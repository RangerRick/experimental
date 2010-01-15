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
