#! /bin/bash

verbose=0
bindir="$HOME/bin"



WHICH=`which which`
AWK=`${WHICH} gawk`
ECHO=`${WHICH} echo`
PYTHON=`${WHICH} python`
PERL=`${WHICH} perl`




INFO_LEVEL=2
DEBUG_LEVEL=3
WARN_LEVEL=1
ERROR_LEVEL=0

function __Debug()
{
        local _fmt=$1
        local _osname=`uname -s | tr [:upper:] [:lower:]`
        shift
        local _backstack=0
        if [ $# -gt 0 ]
                then
                _backstack=$1
        fi
        
        _fmtstr=""
        if [ $verbose -gt $INFO_LEVEL ]
                then
                local _filestack=`expr $_backstack \+ 1`
                _fmtstr="${BASH_SOURCE[$_filestack]}:${BASH_LINENO[$_backstack]} "
        fi

        _fmtstr="$_fmtstr$_fmt"
        if [ "$_osname" = "darwin" ]
                then
                ${ECHO} "$_fmtstr" >&2
        else
                ${ECHO} -e "$_fmtstr" >&2
        fi
}

function Debug()
{
        local _fmt=$1
        shift
        local _backstack=0
        if [ $# -gt 0 ]
                then
                _backstack=$1
        fi
        _backstack=`expr $_backstack \+ 1`
        
        if [ $verbose -ge $DEBUG_LEVEL ]
                then
                __Debug "$_fmt" "$_backstack"
        fi
        return
}

function Info()
{
        local _fmt=$1
        shift
        local _backstack=0
        if [ $# -gt 0 ]
                then
                _backstack=$1
        fi
        _backstack=`expr $_backstack \+ 1`
        
        if [ $verbose -ge $INFO_LEVEL ]
                then
                __Debug "$_fmt" "$_backstack"
        fi
        return
}

function Warn()
{
        local _fmt=$1
        shift
        local _backstack=0
        if [ $# -gt 0 ]
                then
                _backstack=$1
        fi
        _backstack=`expr $_backstack \+ 1`
        
        if [ $verbose -ge $WARN_LEVEL ]
                then
                __Debug "$_fmt" "$_backstack"
        fi
        return
}



function ErrorExit()
{
        local _ec=$1
        local _fmt="$2"
        local _osname=`uname -s | tr [:upper:] [:lower:]`
        local _backstack=0
        if [ $# -gt 2 ]
                then
                _backstack=$3
        fi
        local _fmtstr=""

        if [ $verbose -gt $INFO_LEVEL ]
                then
                _fmtstr="${BASH_SOURCE[$_backstack]}:${BASH_LINENO[$_backstack]} "
        fi
        _fmtstr="$_fmtstr$_fmt"
        if [ "$_osname" = "darwin" ]
        	then
        	echo "$_fmtstr" >&2
        else
        	echo -e "$_fmtstr" >&2
    	fi
        exitcode=$_ec
        exit $_ec
}



TestSudo()
{
	local _res
	_res=0
	sudo -A ls -l >/dev/null
	_res=$? 
	if [ $_res -ne 0 ]
		then
		cat <<EOFMM>> /dev/stderr
you must use visudo to add line to enable no password call sudo
$USER ALL = NOPASSWD: ALL
EOFMM
		exit 4
	fi
}

RunSudoNoOut()
{
	local _res=0
	local _cmd=""
	while [ $# -gt 0 ]
	do
		if [ -z "$_cmd" ]
			then
			_cmd="\"$1\""
		else
			_cmd="${_cmd} \"$1\""
		fi
		shift
	done
	sudo -A /bin/bash -c "${_cmd}" >/dev/null
	_res=$?
	echo "$_res"
	return
}

RunSudoNoOutEnv()
{
	local _res=0
	local _cmd=""
	while [ $# -gt 0 ]
	do
		if [ -z "$_cmd" ]
			then
			_cmd="\"$1\""
		else
			_cmd="${_cmd} \"$1\""
		fi
		shift
	done
	sudo -A -E /bin/bash -c "${_cmd}" >/dev/null
	_res=$?
	echo "$_res"
	return
}


RunSudoOutput()
{
	sudo -A $@
	return
}

RunSudoMustSucc()
{
	local _args=$@
	local _res=0
	_res=$(RunSudoNoOut $@)
	Debug "[$*] _res [$_res]"
	if [ $_res -ne 0 ]
		then
		echo "can not run [$*] [$_res]" >/dev/stderr
		exit 4
	fi
}

RunSudoMustSuccEnv()
{
	local _args=$@
	local _res=0
	_res=$(RunSudoNoOutEnv $@)
	Debug "[$*] _res [$_res]"
	if [ $_res -ne 0 ]
		then
		echo "can not run [$*] [$_res]" >/dev/stderr
		exit 4
	fi
}


RunMustSucc()
{
	local _res
	local _cmd=""
	while [ $# -gt 0 ]
	do
		if [ -z "$_cmd" ]
			then
			_cmd="\"$1\""
		else
			_cmd="${_cmd} \"$1\""
		fi
		shift
	done
	/bin/bash -c "$_cmd" >/dev/null 2>/dev/null
	_res=$?
	if [ $_res -ne 0 ]
		then
		ErrorExit 4 "can not run [${_cmd}]"
	fi
}

run_cmd()
{
	_cmd=$1
	if [ -z "$_cmd" ]
	then
		/bin/echo "no cmd specify" >&2
		exit 2
	fi

	if [ $verbose -lt 3 ] ; then
	/bin/echo -e -n "\e[1;37mrunning ($_cmd)\e[0m" >&2
	fi
	if [ $verbose -lt 3 ]; then
		eval "$_cmd" >/dev/null
	else
		eval "$_cmd"
	fi
	_res=$?
	
	if [  $_res -ne 0 ]
	then
		if [ $verbose -lt 3 ] ; then
			/bin/echo -e "\e[31m[FAILED]\e[0m" >&2
		fi
		exit 3
	fi
	if [ $verbose -lt 3 ] ; then
		/bin/echo -e "\e[32m[SUCCESS]\e[0m" >&2
	fi
}



CheckOS()
{
	local _os
	local _ubuntu
	local _centos
	if [ -f "/etc/os-release" ]
		then
		_os=`cat /etc/os-release | grep -e '^NAME=' | awk -F= '{print $2}'`
		_ubuntu=`echo "$_os" | grep -i ubuntu`
		_centos=`echo "$_os" | grep -i centos`
		if [ -n "$_ubuntu" ]
			then
			ENVOS=ubuntu
		elif [ -n "$_centos" ]
			then
			ENVOS=centos
		else
			ErrorExit 4 "not get os in /etc/os-release"
		fi
	else
		ErrorExit 4 "no /etc/os-release found"
	fi
}

CheckPackageUbuntu()
{
	local _pkg=$1
	local _res=`dpkg -l "$_pkg" | grep "$_pkg" | grep -e '^ii'  2>/dev/null`
	if [ -n "$_res" ]
		then
		echo "0"
	else
		echo "1"
	fi
	return
}

CheckPackageCentOS()
{
	local _pkg=$1
	local _res
	rpm -q $_pkg 2>/dev/null >/dev/null
	_res=$?
	if [ $_res -eq 0 ]
		then
		echo "0"
	else
		echo "1"
	fi
	return
}

CheckPackage()
{
	local _res=0
	local _pkg=$1

	if [ "$ENVOS"  = "ubuntu" ]
		then
		CheckPackageUbuntu "$_pkg"
	elif [ "$ENVOS" = "centos" ]
		then
		CheckPackageCentOS "$_pkg"
	else
		Error 4 "not supported os [$ENVOS]"
	fi
}

CheckPackageMustSucc()
{
	local _res=0
	local _pkg=$1
	$_res=$( CheckPackage "$_pkg" )
	if [ $_res -ne 0 ]
		then
		ErrorExit 4 "[$_pkg] not installed"
	fi
}

InstallPackageUbuntu()
{
	local _pkg=$1
	RunSudoMustSucc apt-get install -y "$_pkg"
}

InstallPackageCentOS()
{
	local _pkg=$1
	RunSudoMustSucc yum install -y "$_pkg"
}

InstallPackage()
{
	local _pkg=$1
	if [ "$ENVOS"  = "ubuntu" ]
		then
		InstallPackageUbuntu "$_pkg"
	elif [ "$ENVOS" = "centos" ]
		then
		InstallPackageCentOS "$_pkg"
	else
		Error 4 "not supported os [$ENVOS]"
	fi
}

CheckOrInstallMustSucc()
{
	local _res
	local _pkg=$1
	_res=$(CheckPackage "$_pkg")
	if [ $_res -ne 0 ]
		then
		InstallPackage "$_pkg"
	fi
}

InstallUpgradePIPPackage()
{
	local _pkg=$1
	RunSudoMustSucc pip install $_pkg	
}

CheckOrCloneDir()
{
	local _url=$1
	local _clonedir=$2
	local _res
	if [ -z "$_clonedir" ]
		then
		_clonedir=`basename $_url | sed 's/\.git$//'`
	fi
	if [ ! -d "{PWD}/${_clonedir}/.git" ]
		then
		if [ ! -d "${PWD}/${_clonedir}" ]
			then
			git clone "$_url"
			_res=$?
			if [ $_res -ne 0 ]
				then
				ErrorExit 4 "can not clone[$_url] [$_res]"
			fi
		fi
	fi
	return
}

CheckIfHomeDir()
{
	local _dir=$1
	local _isok
	local _adir=`readlink -f $_dir`
	_isok=`echo "$_adir" | grep -e '^${HOME}'`
	if [ "$_isok" = "$_adir" ]
		then
		echo "0"
	else
		echo "1"
	fi
	return
}

RunDstMustSucc()
{
	local -a _args
	local _i=0
	local _ishome=0
	while [ $# -gt 0 ]
	do
		_args[$_i]=$1
		shift
		_i=`expr $_i + 1`
	done
	Debug "_args [${_args[*]}]"
	_ishome=$(CheckIfHomeDir "$bindir")
	if [ $_ishome -gt 0 ]
		then
		RunMustSucc ${_args[@]}
	else
		RunSudoMustSucc ${_args[@]}
	fi
}

CopyOnDstDir()
{
	local _src=$1
	Debug "src [$_src]"
	if [  -d "$_src" ]
		then
		RunDstMustSucc cp -r "$_src" "$bindir"
	elif [ -f "$_src" ]
		then
		RunDstMustSucc cp "$_src" "$bindir"
	fi

	return

}

CheckCPANCentOS()
{
	local _res
	_res=$(RunSudoNoOut sudo timeout 1 sudo cpan -J)
	if [ $_res -ne 0 ]
		then
		# to make the cpan init
		( echo y;echo o conf prerequisites_policy follow;echo o conf commit ) | sudo cpan
		_res=$?
		if [ $_res -ne 0 ]
			then
			ErrorExit 4 "can not run cpan init ok [$_res]"
		fi
	fi
}

CPANInstall()
{
	local _pkg=$1
	RunSudoMustSucc cpan install "$_pkg"
}



run_scripts()
{
	local _d=$1
	local _res


	if [ ! -d "$_d" ]; then
		return
	fi

	for _f in $(ls "$_d" | sort)
	do
		_isok=`echo "$_f" | egrep -e '[\/]?[0-9]+_[^\/]+$'`
		if [ -f "$_d/$_f" ] && [ -e "$_d/$_f" ] && [ -n "$_isok" ]
			then
			bash "$_d/$_f"
			_res=$?
			if [ $_res -ne 0 ]
				then
				ErrorExit 4 "can not run [$_d/$_f] ok"
			fi
			Debug "run [$_d/$_f] ok"
		fi
	done
}

_scriptfile=`readlink -f $0`
if [ -z "$_scriptfile" ]
	then
	_scriptfile=`which $0`
fi
_scriptdir=`dirname $_scriptfile`

declare -a DEFAULT_DPKG_FILE
declare -a DEFAULT_PIP_FILE


DEFAULT_DPKG_FILE[0]="$_scriptdir/dpkg.txt"

DEFAULT_PIP_FILE[0]="$_scriptdir/pip.txt"


TestSudo


Usage()
{
	_ec=$1
	_fmt=$2
	_echoout=/dev/stderr
	if [ $_ec -eq 0 ]
	then
		_echoout=/dev/stdout
	fi

	if [ -n "$_fmt" ]
		then
		echo -e "$_fmt" >$_echoout
	fi

	echo -e "init [OPTIONS] [initdirs...]" >$_echoout
	echo -e "\t--help|-h                          to display this help information" >$_echoout
	echo -e "\t--verbose|-v                       to make verbose mode" >$_echoout
	echo -e "\t--bindir|-d      bindir            to specify the bin dir to install for self use" >$_echoout
	echo -e "\t--dpkg|-D        file              to add the dpkg install files default[${DEFAULT_DPKG_FILE[@]}]" >$_echoout
	echo -e "\t--pip|-p         file              to add pip file default [${DEFAULT_PIP_FILE[@]}]" >$_echoout
	echo -e "" >$_echoout
	echo -e "initdirs  ... will run scripts in the initdirs" >$_echoout
	exit $_ec
}

declare -a pip_install_files
declare -a dpkg_install_files

CheckOS

while [ $# -gt 0 ]
do
	_curarg=$1
	if [ "$_curarg" = "--help" ] || [ "$_curarg" = "-h" ]
		then
		Usage 0 ""
	elif [ "$_curarg" = "--verbose" ] || [ "$_curarg" = "-v" ]
		then
		verbose=`expr $verbose + 1`
	elif [ "$_curarg" = "--bindir" ] || [ "$_curarg" = "-d" ]
		then
		if [ $# -lt 2 ]
			then
			Usage 3 "[$_curarg] need an arg"
		fi
		bindir=$2
		shift
	elif [ "$_curarg" = "--dpkg" ] || [ "$_curarg" = "-D" ]
		then
		if [ $# -lt 2 ]
			then
			Usage 3 "[$_curarg] need an arg"
		fi
		_num=${#dpkg_install_files[@]}
		dpkg_install_files[$_num]=$2
		shift
	elif [ "$_curarg" = "--pip" ] || [ "$_curarg" = "-p" ]
		then
		if [ $# -lt 2 ]
			then
			Usage 3 "[$_curarg] need an arg"
		fi
		_num=${#pip_install_files[@]}
		pip_install_files[$_num]=$2
		shift		
 	elif [ "$_curarg" = "--" ]
 		then
 		shift
 		break
 	else
		break
	fi
	shift
done

_num=${#dpkg_install_files[@]}
if [  $_num -eq 0 ]
	then
	dpkg_install_files=$DEFAULT_DPKG_FILE
fi

_num=${#pip_install_files[@]}
if [ $_num -eq 0 ]
	then
	pip_install_files=$DEFAULT_PIP_FILE
fi

for _c in ${dpkg_install_files[@]}
do
	for _l in $(cat $_c)
	do
		CheckOrInstallMustSucc "$_l"
	done
done

for _c in ${pip_install_files[@]}
do
	RunSudoMustSucc python -m pip install --quiet -r "$_c"
done


_isok=`which extargsparse4sh`
if [ -z "$_isok" ]
	then
	CheckOrCloneDir https://github.com/jeppeter/extargsparse4sh.git

	if [ -n "$bindir" ] && [ ! -d "$bindir" ]
		then
		mkdir -p "$bindir"
	fi

	export PATH=$PATH:$bindir
	(pushd ${PWD} && cd extargsparse4sh && make && popd) || ErrorExit 4 "can not make extargsparse4sh"
	CopyOnDstDir extargsparse4sh/extargsparse4sh
fi

_isok=`echo $PATH | awk -F: '{for(i=1;i<NF;i++){printf("%s\n",$i);}}' | grep -e "^$bindir\$"`
if [ -z "$_isok" ]
	then
	cat <<EOFMM>> $HOME/.bashrc
	export PATH=\$PATH:$bindir
EOFMM
fi

if [ $# -gt 0 ]
	then
	for _i in $@
	do
		run_scripts "$_i"
	done
else
	run_scripts "$_scriptdir/initsh"
fi
