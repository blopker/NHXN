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
    comments*: seq[Comment]

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

let cache = newLRUCache[int, JsonNode](10000) 
var stories: seq[Story] = @[]

proc httpGet(id: int): Future[JsonNode] {.async, gcsafe.} =
    if id in cache:
        return cache[id]
    var client = newAsyncHttpClient()
    let json = parseJson(await client.getContent(&"https://hacker-news.firebaseio.com/v0/item/{id}.json"))
    client.close()
    cache[id] = json
    return json

proc getComment(id: int): Future[Comment] {.async.} =
    var json = await httpGet(id)
    if json{"deleted"}.getBool(false):
        return Comment()
    let kids = json{"kids"}.getElems().map((x) => x.getInt())
    let comments = await all(kids.map(getComment))
    echo json
    return Comment(id: json["id"].getInt(), by: json["by"].getStr(), kids: kids, comments: comments, time: json["time"].getInt(), text: json["text"].getStr())

proc fetchStory(id: int): Future[Story] {.async.} =
    var json = await httpGet(id)
    let kids = json{"kids"}.getElems().map((x) => x.getInt())
    let comments = await all(kids.map(getComment))
    return Story(id: json["id"].getInt(), by: json["by"].getStr(), 
        time: json["time"].getInt(), kids: kids,
        url: json["url"].getStr(), score: json["score"].getInt(), title: json["title"].getStr(),
        descendants: json{"descendants"}.getInt(0), comments: comments)

proc fetchStories*(): Future[seq[Story]] {.async.} =
  var client = newAsyncHttpClient()
  let storyIDs = to(parseJson(
      await client.getContent("https://hacker-news.firebaseio.com/v0/topstories.json")), 
      seq[int])
  client.close()
  return await all(storyIDs[0..29].map(fetchStory))

proc getStories*(): seq[Story] {.gcsafe.} = stories

proc getStory*(id: int): Future[Story] {.async.} = 
    return await fetchStory(id)

proc apiListen*() {.async.} = 
    while true:
        echo "get stories"
        stories = await fetchStories()
        await sleepAsync(30*1000)

proc main() {.async.} = 
    echo await fetchStories()

if isMainModule:
    # waitFor main()
    waitFor apiListen()