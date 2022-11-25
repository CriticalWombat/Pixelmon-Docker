#!/bin/sh
[ ! -d "/data/mod" ] && cp -rf /pixelmon/* /data

java -Xms1G -Xmx4G -jar /pixelmon/forge.jar
