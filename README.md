# Pixelmon-Docker
A Log4J mitigated and updated Pixelmon server in Docker.

**DISCLAIMER: I have mitigated Log4J as best as I know. You are responsible for ensuring it is fully secure.
I have tested basic log4j exploits against my own running instance and was unable to trigger the vulnerability.**

**NOTE: Default exposed port is 30050. If you want a different port, make sure to edit the dockerfile too!**

ATLauncher versioning:

    Pixelmon client: 1.16.5-9.0.10

# Jar files used:

  https://maven.minecraftforge.net/net/minecraftforge/forge/1.16.5-36.2.39/forge-1.16.5-36.2.39-installer.jar
  
  https://repo.spongepowered.org/repository/maven-releases/org/spongepowered/spongeforge/1.16.5-36.2.5-8.1.0-RC1202/spongeforge-1.16.5-36.2.5-8.1.0-RC1202-universal.jar
  
  https://dl.reforged.gg/3BvPBUv  - (Pixelmon-1.16.5-9.0.10-universal.jar)
  
  
# Docker commands:
Navigate to the same directory as your Dockerfile and build it:

    docker build . -t pixelmon

Once your image is done building, run the following to create your container named pixelmon:

    docker run -d --name "pixelmon" -p 30050:25565/tcp -p 30050:25565/udp pixelmon
    
    
**Note: It is advisable to create a persistant volume to keep your data once you turn off or destroy your docker container.**

If you wanted to save your container's data to **/opt/docker/pixelmon-volume** you could run the following:
    
    docker run -d --name "pixelmon" -p 30050:25565/tcp -p 30050:25565/udp -v /opt/docker/pixelmon-volume:/data pixelmon

	
# Log4j mitigation:

Once the container is built, navigate to the /data directory either through your mapped volume or by entering the container.

Forge and Pixelmon jar files do not have the jndi lookup class built in, however, vanilla 1.16.5 does.

Run the following to unpack the jar file:

    cd Pixelmon-Docker && mkdir tmp && mv minecraft_server.1.16.5.jar tmp/minecraft_server.1.16.5.jar && cd tmp && jar -xvf minecraft_server.1.16.5.jar

Use your text editor of choice to make the below alterations:
Find the log4j2.xml file. Edit this file to add '{nolookups}' wherever you find it in the following spaces:

	<Configuration status="WARN">
	<Appenders>
	<Console name="SysOut" target="SYSTEM_OUT">
	<PatternLayout pattern="[%d{HH:mm:ss}] [%t/%level]: %msg{nolookups}%n"/>
	</Console>
	<Queue name="ServerGuiConsole">
	<PatternLayout pattern="[%d{HH:mm:ss} %level]: %msg{nolookups}%n"/>
	</Queue>
	<RollingRandomAccessFile name="File" fileName="logs/latest.log" filePattern="logs/%d{yyyy-MM-dd}-%i.log.gz">
	<PatternLayout pattern="[%d{HH:mm:ss}] [%t/%level]: %msg{nolookups}%n"/>
	<Policies>
	<TimeBasedTriggeringPolicy/>
	<OnStartupTriggeringPolicy/>
	</Policies>
	</RollingRandomAccessFile>
	</Appenders>
	<Loggers>
	<Root level="info">
	<filters>
	<MarkerFilter marker="NETWORK_PACKETS" onMatch="DENY" onMismatch="NEUTRAL"/>
	</filters>
	<AppenderRef ref="SysOut"/>
	<AppenderRef ref="File"/>
	<AppenderRef ref="ServerGuiConsole"/>
	</Root>
	</Loggers>
	</Configuration>
	
Run the following to repackage the jarfile:

	rm minecraft_server.1.16.5.jar && jar -cvf minecraft_server.1.16.5.jar ./* && mv minecraft_server.1.16.5.jar ../minecraft_server.1.16.5.jar && cd ../ && rm -r tmp
