# shellcheck shell=sh

pick_random() (
	rnd=$(od -vAn -N2 -tu2 < /dev/urandom)
	result=$(("$rnd" % $# + 1))

	eval echo \$$result
)
