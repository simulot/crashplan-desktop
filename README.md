# crashplan-desktop
Run Crashplan GUI in a docker container indpendently for installed instance. This allow managing a remote instance of Crashplan running on a NAS

I have installed CrashPlan service on my NAS to backup it precisous content. Read this article http://support.code42.com/CrashPlan/Latest/Configuring/Using_CrashPlan_On_A_Headless_Computer for details. 

Crashplan is also installed on my Ubuntu workstation. Both instances used to work. But at occasion of an update, I wasn't able to manage the NAS service using my workstation. Code42 has added a bunch of new features that make the headless setup less usable.

So the need to run separate instance of Crashplan became obivioius. Of course runing an instanace of VirtualBox would fit peferctly this need, but I would like to have as less as possible overhead just for runing an GUI application.

So why not running an controlled version of Crashplan in a container, independant from the one running on the host station? It would have it's own .ui_info file that wont be overriden by main instance of CrashPlan.

Credits:

Docker container for Crashplan Desktop : gfjardim/crashplan-desktop
Blog post on running GUI application from containers: https://blog.jessfraz.com/post/docker-containers-on-the-desktop/
The trick for running X11 application from a container:  http://stackoverflow.com/a/25280523


