<pre>__        ___    ____  _   _ ___ _   _  ____ _ 
\ \      / / \  |  _ \| \ | |_ _| \ | |/ ___| |
 \ \ /\ / / _ \ | |_) |  \| || ||  \| | |  _| |
  \ V  V / ___ \|  _ &lt;| |\  || || |\  | |_| |_|
   \_/\_/_/   \_\_| \_\_| \_|___|_| \_|\____(_)</pre>

THIS IS CALLED "EXPERIMENTAL" FOR A REASON.  DO NOT TELL RANGER RICK ABOUT BUGS IN PACKAGES HERE
UNLESS YOU ARE EXPLICITLY ASKED FOR FEEDBACK.  SERIOUSLY.

Yes, this means *you*!

<pre> ____  _____ ____  ___ ___  _   _ ____  _  __   ___ 
/ ___|| ____|  _ \|_ _/ _ \| | | / ___|| | \ \ / / |
\___ \|  _| | |_) || | | | | | | \___ \| |  \ V /| |
 ___) | |___|  _ &lt; | | |_| | |_| |___) | |___| | |_|
|____/|_____|_| \_\___\___/ \___/|____/|_____|_| (_)</pre>

;)

OK
==

Now that that's finished, let's continue.

To use the rangerrick experimental branch, check out with:

  git clone git://github.com/RangerRick/experimental.git /sw/fink/dists/local/rangerrick
  cd /sw/fink/dists/local/rangerrick

Then, edit /sw/etc/fink.conf and add "local/rangerrick/10.4/main" or "local/rangerrick/10.7/main"
to your "Trees:" line (depending on your distro).

To update your tree, use "git pull":

  cd /sw/fink/dists/local/rangerrick
  git pull

