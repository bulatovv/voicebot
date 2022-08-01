# shellcheck shell=sh

RANDSTATE=$(date +%s)
RANDSTATE=$((RANDSTATE + $$))
rand() {
	RANDSTATE=$((RANDSTATE * 1103515245 + 12345))
	( 
		result=$(( RANDSTATE / 65536 % 32768 ))
		echo "${result#-}"
	)
}

pick_random() (
	eval echo \$$(($(rand) % $# + 1))
)
