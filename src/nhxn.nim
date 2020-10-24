import prologue
import prologue/middlewares/staticfile
import strutils
from pages import indexPage, storyPage
from api import getStories, apiListen, getStory

proc index*(ctx: Context) {.async.} =
  let stories = getStories()
  resp indexPage(stories)

proc story*(ctx: Context) {.async, gcsafe.} =
  let id = parseInt(ctx.getPathParams("id", "0"))
  let story = await getStory(id)
  resp storyPage(story)

let settings = newSettings(debug = true)
var app = newApp(settings)
app.use(staticFileMiddleware("public"))
app.addRoute("/", index)
app.addRoute("/story/{id}", story)
asyncCheck(apiListen())
app.run()
