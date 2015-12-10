# NoiseGen

The most important function of this repository is to continue work on contriboard-noise-tester (https://github.com/N4SJAMK/contriboard-noise-tester)

What has been done so far:

# Implementation that works with Contriboard by Teemu Kontio and Jan Kuukkanen (the repository mentioned above)

Comments:
- This implementation has been made in short time and it basically consists of web UI and scripts to manipulate Linux qdisc command with various parameters.
- To create a more general noise generator that works with all kinds of websites and services, the work should basically be started from scratch.

# Additional research on more general approach by Tero Oinonen and a lot of help from Janne Alatalo

IMPORTANT NOTE: The following guide tries to explain what was done and how, but at least the initial research showed that running PPTP VPN server within Docker container has several pretty severe issues. It would probably be a better option to start from scratch and use for example OpenVPN within Docker container, or as a less secure method, use ansible scripts to create a new virtual machine with certain configurations when the previous one breaks. This, however, does not prevent user from doing something harmful inside the virtual machine that may be unwanted to the account owner. OpenVPN method would probably be the best bet, but making a good practice for user authentication that requires as little effort from the end user as possible could take time. This is due to OpenVPN using a platform-specific client and CA files to generate .ovpn authentication file on client-side device.

# Research documentation

The idea was to take a look at contriboard-noise-tester code and make a more generic version of it. Some research was done to see what would be the most secure and simple method of implementation. After all the approach chosen was to try and run PPTP VPN server within Docker container. This lead to several problems. At first PPTP daemon did not start at all. This was fixed by starting docker container with additional parameters. At this point it would be good to gather some basic knowledge on how docker works and what commands to use. Docker has pretty good documentation and tutorials on their website.

However, here's a short summary on important commands and what they do (unless you have dedicated docker user with enough privileges, you should sudo):
docker images ← this shows a list of built images
docker ps  ←this shows a list of running containers
docker rmi ← a command for removing a certain image, may be enforced with -f parameters

When you have a Dockerfile with instuctions on how to build a docker image, you'll be able to use the following command to create a new image: 
docker build -t <image name> <location of Dockerfile> ←where -t is a parameter that allows you to name the image created
Example command: docker build -t test .    ←Here “.” means that Dockerfile is located in the current folder.

Here's an example of a command that got us this far, that PPTP daemon was running inside container:
sudo docker run -d --privileged -p 1723:1723 <container name> ← here privileged parameter is necessary to give PPTP daemon enough privileges to run, and -p command forwards host machine port 1723 to docker container port 1723. Port 1723 is used by PPTP daemon.

# About supervisord

Supervisord configuration is used to run certain services in docker container with better privileges. When it was tried to start some services directly from Dockerfile, it seemed that those services didn't stay running. With supervisord we managed to avoid this issue somewhat well. Supervisord configuration resides in supervisord.conf file and it basically defines running parameters for SSH daemon and PPTP.  This same method could probably be used with some other services, but in this case these two were deemed the most critical. The Dockerfile contains some commands necessary to make supervisord work.

# Short explanation on the Dockerfile:

It would basically be possible to make a docker container, run it and then install some services within it and then save it as an image. However, this is not a good practice and at least in our case it caused some services, SSH and PPTP in particular, not stay running after initial startup. 

Therefore it is wise to contain all the possible configuration within the Dockerfile and use it in creating a new image. What our Dockerfile does is the following:

- Takes an Ubuntu 14.04 image from docker's own container repositories
- runs apt-get update and then installs the services and tools required
- makes some necessary directories for logging and services to run correctly
- copies our configurations to their respective directories within the docker container
- restarts pptp daemon after configurations have been set in place
- because the docker container is by default run as root and its password is a bit tricky to get (though not impossible, you can do it if you want to look into it), we create another user for accessing the container via SSH and echo the password to it. In a format dockeruser:dockeruser the first one is the username, and second is the password.
- after that dockeruser is added to sudo group, therefore giving it privileges to sudo
- iptables configurations are a bit tricky in this case, and they should be given more thorough research, for these configurations could possibly be improved
- iptables-persistent allows iptables configurations to stay over boot, otherwise they will reset on reboot. In this case the similar configurations have also been added to rc.local -file, which also retains these settings over reboot.
- and finally, we expose ports 22 and 1723 to be used into docker container for SSH and PPTP to work, and then run supervisord that starts SSH and PPTP daemons

It is strongly recommended to change the username – password combination in chap-secrets -file, for this data is only for example purposes to understand the format this file uses.

Current state:

This approach has worked during testing up to the point where client tries to connect to PPTP server within docker container. At this point SSH and other connections to container are lost and only regained after PPTP VPN connection crashes/ timeouts. The cause of this is as of yet unknown, but it may well be some kind of compatibility issue between docker and PPTP protocol. It was mentioned somewhere that PPTP using old GRE protocol would be the main cause for these issues, but it could also be more complicated than this.
