__        ___    ____  _   _ ___ _   _  ____ _ 
\ \      / / \  |  _ \| \ | |_ _| \ | |/ ___| |
 \ \ /\ / / _ \ | |_) |  \| || ||  \| | |  _| |
  \ V  V / ___ \|  _ <| |\  || || |\  | |_| |_|
   \_/\_/_/   \_\_| \_\_| \_|___|_| \_|\____(_)
                                               
THIS IS CALLED "EXPERIMENTAL" FOR A REASON.  DO NOT TELL RANGER RICK ABOUT BUGS IN PACKAGES HERE
UNLESS YOU ARE EXPLICITLY ASKED FOR FEEDBACK.  SERIOUSLY.

Yes, this means you!

 ____  _____ ____  ___ ___  _   _ ____  _  __   ___ 
/ ___|| ____|  _ \|_ _/ _ \| | | / ___|| | \ \ / / |
\___ \|  _| | |_) || | | | | | | \___ \| |  \ V /| |
 ___) | |___|  _ < | | |_| | |_| |___) | |___| | |_|
|____/|_____|_| \_\___\___/ \___/|____/|_____|_| (_)
                                                    
;)

===================================================================================================

Now that that's finished, let's continue.

To use the rangerrick experimental branch, check out with:

  git clone http://www.finkproject.org/~ranger/experimental.git /sw/fink/dists/local/rangerrick
  cd /sw/fink/dists/local/rangerrick
  git checkout -b kde4.4 remotes/origin/kde4.4

Then, edit /sw/etc/fink.conf and add the following entries to the front
of your "Trees:" line:

	local/rangerrick/3rdparty/common/main
	local/rangerrick/3rdparty/common/crypto
	local/rangerrick/common/main
	local/rangerrick/common/crypto
	local/rangerrick/10.4/main
	local/rangerrick/10.4/crypto

To update your tree, use "git pull":

  cd /sw/fink/dists/local/rangerrick
  git pull

