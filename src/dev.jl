using Revise
using qBittorrentStats
using HTTP

username="admin"
baseurl = "http://qbittorrentdockervm.diro.ch"

cookie = auth_login(baseurl)

"http://qbittorrentdockervm.diro.ch/api/v2/auth/login"