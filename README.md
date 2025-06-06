# qBittorrentStats

[![Build Status](https://github.com/kafisatz/qBittorrentStats.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/kafisatz/qBittorrentStats.jl/actions/workflows/CI.yml?query=branch%3Amaster)

## Purpose
* Gathers data (per torrent) from a qBittorrent client via WebUI API (https://github.com/qbittorrent/qBittorrent/wiki/#webui-api)
* writes summary statistics to docker log
* Data is optionally written to InfluxDBv2

## Requirements 
* InfluxDBv2 instance 
* A qBittorrent client with WebUI API enabled.

## Limitations 
* For me this is currently not working when I use a https URL (reverse proxy). Instead I am using the IP of the client

## Usage
```julia
#you should make sure that https://github.com/kafisatz/InfluxDBClient.jl works properly for you
#see https://github.com/kafisatz/InfluxDBClient.jl#configuration
using InfluxDBClient
isettings = get_settings()
#check if the InfluxDB is reachable
bucket_names, json = get_buckets(isettings);

#if the above works, proceed as follows

using qBittorrentStats

#URL of the WebUI; this should show the Web UI login page of qBittorrent
baseurl = "http://10.14.15.205:8080"

#credentials and settins for InfluxDB
influxdbsettings = InfluxDBClient.get_settings()

#a bucket name in InfluxDB
#Make sure this bucket is first created. Otherwise you will get a warning message and no data will be written
influxdbbucketname = "qBittorrentStats"

lastactivitydf,js,cookieDict = getstats(baseurl,password=password);

#lastactivitydf is a dataframe which contains the information for each torrent

#the data is gathered via https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-generic-properties
#see the property list on that page
#Notably only a subset of the properties is written to InfluxDB as the motivation for this package was upload and download volumes to manage storage tiering (and deletion) of torrents
```