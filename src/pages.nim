import karax / [karaxdsl, vdom]
import strformat
import api


proc base(content: string): string =
  &"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="x-ua-compatible" content="ie=edge">
    <title>NHXN</title>
    <link rel="icon" href="/public/favicon.ico" type="image/x-icon" />
    <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
    <link rel="stylesheet" href="/public/main.css" />
</head>
    <body>
        <a href="/">
            <header>
                <div class="header-title">
                    <h3>NHXN</h3>
                </div>
            </header>
        </a>
        <div id="container" class="items">
          { content }
        </div>
        <footer>
            Yolo'd by blopker. <a href="https://github.com/blopker/gohxn">Source</a>.
        </footer>
        <script src="/public/main.js"></script>
    </body>
</html>
  """

# <div>
# {{ range .Ctx }}

#     <div class="list-item">
#         <a href="{{ .URL }}">
#             <div class="story">
#                 <h3>{{ .Title }}</h3>
#                 <div class="host">{{ .DisplayURL }}</div>
#             </div>
#         </a>
#         <a href="/comments/?id={{ .ID }}">
#             <aside>
#                 <div class="comment-count">{{ .Descendants }}</div>
#                 <div class="score">{{ .Score }}</div>
#             </aside>
#         </a>
#     </div>

# {{end}}
# </div>

proc indexPage*(stories: seq[Story]): string =
  let vnode = buildHtml(tdiv()):
    tdiv:
      for story in stories:
        tdiv(class = "list-item"): 
          a(href = story.url):
            tdiv(class = "story"):
              h3: text story.title
              tdiv(class = "host"): text story.url
          a(href = &"/story/{story.id}"):
            aside:
              tdiv(class = "comment-count"): text &"{story.descendants}"
              tdiv(class = "score"): text &"{story.score}"
  result = base($vnode)


# <div class="js-comment comment">
#     <div class="js-author author">{{ .By }}</div>
#     <div class="text">{{ .HTML }}</div>
#     {{ template "children" .KidItems }}
# </div>
proc child(comment: Comment): Vnode = 
  let vnode = buildHtml(tdiv(class = "js-comment comment")):
    tdiv(class = "js-author author"): text comment.by
    tdiv(class = "text"): verbatim comment.text
    for c in comment.comments:
      tdiv(class = "children"): child(c)
  return vnode

# <div>
#     <div class="comment-header">
#         <h3>{{ .Ctx.Title }}</h3>
#         <a href={{ .Ctx.URL }}>{{ .Ctx.DisplayURLLong }}</a>
#         <div class="comment-header-author">By: {{ .Ctx.By }}</div>
#         <div class="text">{{ .Ctx.HTML }}</div>
#     </div>
#     <div class="comments">
#         {{ range .Ctx.KidItems }}
#             {{ template "child" .}}
#         {{ end }}
#     </div>
# </div>
proc storyPage*(story: Story): string =
  let vnode = buildHtml(tdiv()):
    tdiv:
      tdiv(class = "comment-header"):
        h3: text story.title
        a(href = story.url): text story.url
        tdiv(class = "comment-header-author"): text &"By: {story.by}"
        # tdiv(class = "text"): text story.text
      tdiv(class = "comments"):
        for comment in story.comments:
          tdiv: child(comment)

  result = base($vnode)