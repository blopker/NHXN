import asyncdispatch, httpclient
import std/[json]
import strformat
import sequtils
import sugar
import lrucache

# {
#   "by" : "dhouston",
#   "descendants" : 71,
#   "id" : 8863,
#   "kids" : [ 8952, 9224, 8917, 8884, 8887, 8943, 8869, 8958, 9005, 9671, 8940, 9067, 8908, 9055, 8865, 8881, 8872, 8873, 8955, 10403, 8903, 8928, 9125, 8998, 8901, 8902, 8907, 8894, 8878, 8870, 8980, 8934, 8876 ],
#   "score" : 111,
#   "time" : 1175714200,
#   "title" : "My YC app: Dropbox - Throw away your USB drive",
#   "type" : "story",
#   "url" : "http://www.getdropbox.com/u/2/screencast.html"
# }
type
  Story* = object
    id*: int
    by*: string
    time*: int
    kids*: seq[int]
    url*: string
    score*: int
    title*: string
    descendants*: int

# {
#   "by" : "norvig",
#   "id" : 2921983,
#   "kids" : [ 2922097, 2922429, 2924562, 2922709, 2922573, 2922140, 2922141 ],
#   "parent" : 2921506,
#   "text" : "Aw shucks, guys ... you make me blush with your compliments.<p>Tell you what, Ill make a deal: I'll keep writing if you keep reading. K?",
#   "time" : 1314211127,
#   "type" : "comment"
# }
  Comment* = object
    id*: int
    by*: string
    text*: string
    kids*: seq[int]
    time*: int
    comments*: seq[Comment]

var cache {.threadvar.}: LruCache[int, JsonNode]
var stories {.threadvar.}: seq[Story]

proc fetchItem(id: int): Future[JsonNode] {.async.} =
  if isNil(cache):
    cache = newLRUCache[int, JsonNode](10000) 
  if id in cache and not isNil(cache[id]) :
    return cache[id]
  var client = newAsyncHttpClient()
  let json = parseJson(await client.getContent(&"https://hacker-news.firebaseio.com/v0/item/{id}.json"))
  client.close()
  # echo json
  cache[id] = json
  return json

proc getComment(id: int): Future[Comment] {.async, gcsafe.} =
    let json = await fetchItem(id)
    if isNil(json) or json{"deleted"}.getBool(false):
        return Comment()
    let kids = json{"kids"}.getElems().map((x) => x.getInt())
    let comments = await all(kids.map(getComment))
    # echo json
    try:
      return Comment(id: json["id"].getInt(), by: json["by"].getStr(), kids: kids, comments: comments, time: json["time"].getInt(), text: json["text"].getStr())
    except:
      echo json

proc getStoriesJson(): Future[seq[JsonNode]] {.async.} = 
  var client = newAsyncHttpClient()
  let storyIDs = to(parseJson(
      await client.getContent("https://hacker-news.firebaseio.com/v0/topstories.json")), 
      seq[int])
  client.close()
  var storiesJson = await all(storyIDs[0..29].map(fetchItem))
  storiesJson = storiesJson.filter((x) => x["type"].getStr() == "story")
  return storiesJson

proc createStory(json: JsonNode): Story =
  let kids = json{"kids"}.getElems().map((x) => x.getInt())
  return Story(id: json["id"].getInt(), by: json["by"].getStr(), 
        time: json["time"].getInt(), kids: kids,
        url: json{"url"}.getStr(""), score: json["score"].getInt(), title: json["title"].getStr(),
        descendants: json{"descendants"}.getInt(0))

proc fetchStories*(): Future[seq[Story]] {.async.} =
  let storiesJson = await getStoriesJson()
  return storiesJson.map(createStory)

proc getStories*(): seq[Story] = stories

proc getStory*(id: int): Future[Story] {.async.} = 
  let json = await fetchItem(id)
  return createStory(json)

proc getComments*(story: Story): Future[seq[Comment]] {.async.} =
  return await all(story.kids.map(getComment))

proc apiListen*() {.async.} =
    while true:
        echo "get stories"
        stories = await fetchStories()
        for story in stories:
          # just prime cache
          asyncCheck getComments(story)
        await sleepAsync(30*1000)

proc main() {.async.} = 
    echo await fetchStories()

if isMainModule:
    # waitFor main()
    waitFor apiListen()