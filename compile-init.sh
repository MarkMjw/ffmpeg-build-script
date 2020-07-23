#! /usr/bin/env bash

LOCAL_REPO=repo

# ffmpeg版本
FFMPEG_VERSION=ffmpeg-4.3.1
FFMPEG_UPSTREAM=http://ffmpeg.org/releases/${FFMPEG_VERSION}.tar.gz

# x264版本
X264_VERSION=x264-stable
X264_UPSTREAM=https://code.videolan.org/videolan/x264/-/archive/stable/${X264_VERSION}.tar.gz

# fdkaac版本
FDKAAC_VERSION=fdk-aac-2.0.1
FDKAAC_UPSTREAM=http://downloads.sourceforge.net/opencore-amr/$FDKAAC_VERSION.tar.gz

# mp3lame版本
MP3LAME_VERSION=lame-3.100
MP3LAME_UPSTREAM=http://downloads.sourceforge.net/project/lame/lame/3.100/${MP3LAME_VERSION}.tar.gz

# 显示当前shell的所有变量(环境变量，自定义变量，与bash接口相关的变量)
set -e
# 公用工具脚本路径
TOOLS=tools

# $1 表示执行shell脚本时输入的参数 比如./init-android.sh arm64 x86_64 $1的值为arm64;$1的值为x86_64
# $0 当前脚本的文件名
# $# 传递给脚本或函数的参数个数。
# $* 传递给脚本或者函数的所有参数;
# $@ 传递给脚本或者函数的所有参数;
# 两者区别就是 不被双引号(" ")包含时，都以"$1" "$2" … "$n" 的形式输出所有参数。而"$*"表示"$1 $2 … $n";
# "$@"依然为"$1" "$2" … "$n"
# $$ 脚本所在的进程ID
# $? 上个命令的退出状态，或函数的返回值。一般命令返回值 执行成功返回0 失败返回1
FF_TARGET_HOST=$1

# 源码fork到本地的路径;默认Android平台
FORK_SOURCE=android/forksource

function dowload_source_code() {
    mkdir -p $LOCAL_REPO
    cd $LOCAL_REPO

    # FFmpeg源码
    if [ ! -d "${FFMPEG_VERSION}" ]; then
        if [ ! -f "${FFMPEG_VERSION}.tar.gz" ]; then
            echo "Downloading ${FFMPEG_VERSION}.tar.gz"
            curl -LO $FFMPEG_UPSTREAM
        fi
        echo "extracting ${FFMPEG_VERSION}.tar.gz"
        tar -xf ${FFMPEG_VERSION}.tar.gz
    else
        echo "Using existing `pwd`/${FFMPEG_VERSION}"
    fi

    # x264源码
    if [ ! -d "$X264_VERSION" ] && [ ${LIBFLAGS[0]} == "TRUE" ]; then
        if [ ! -f "$X264_VERSION.tar.gz" ]; then
            echo "Downloading $X264_VERSION"
            curl -LO $X264_UPSTREAM
        fi
        echo "extracting $X264_VERSION.tar.gz"
        tar -xf $X264_VERSION.tar.gz
    else
        echo "Using existing `pwd`/$X264_VERSION ${LIBFLAGS[0]}"
    fi

    # fdk-acc源码
    if [ ! -d "${FDKAAC_VERSION}" ] && [ ${LIBFLAGS[1]} == "TRUE" ]; then
        if [ ! -f "${FDKAAC_VERSION}.tar.gz" ]; then
            echo "Downloading ${FDKAAC_VERSION}"
            curl -LO $FDKAAC_UPSTREAM
        fi
        echo "extracting ${FDKAAC_VERSION}.tar.gz"
        tar -xf ${FDKAAC_VERSION}.tar.gz
    else
        echo "Using existing `pwd`/${FDKAAC_VERSION} ${LIBFLAGS[1]}"
    fi

    # mp3lame源码
    if [ ! -d "${MP3LAME_VERSION}" ] && [ ${LIBFLAGS[2]} == "TRUE" ]; then
        if [ ! -f "${MP3LAME_VERSION}.tar.gz" ]; then
            echo "Downloading ${MP3LAME_VERSION}"
            curl -LO $MP3LAME_VERSION
        fi
        echo "extracting ${MP3LAME_VERSION}.tar.gz"
        tar -xf ${MP3LAME_VERSION}.tar.gz
        # curl -L -o lame-${LAME_VERSION}/config.guess "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD"
        # curl -L -o lame-${LAME_VERSION}/config.sub "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD"
    else
        echo "Using existing `pwd`/${MP3LAME_VERSION} ${LIBFLAGS[2]}"
    fi

    cd ..
}

# $1 代表平台 armv5 arm64...
# $2 代表库的名称 ffmpeg x264
# $3 代表库在本地的路径
function fork_source_code() {
    is_pull=TRUE
    if [ $2 == "x264" ] && [ ${LIBFLAGS[0]} == "FALSE" ];then
        is_pull=FALSE
    elif [ $2 == "fdk-aac" ] && [ ${LIBFLAGS[1]} == "FALSE" ];then
        is_pull=FALSE
    elif [ $2 == "mp3lame" ] && [ ${LIBFLAGS[2]} == "FALSE" ];then
        is_pull=FALSE
    fi
    if [ "$is_pull" == "FALSE" ];then
        return
    fi
    
    echo "== pull $2 fork $1 =="
    # 平台对应的forksource目录下存在对应的源码目录，则默认已经有代码了，不拷贝了；如果要重新拷贝，先删除存在的源码目录
    if [ -d $FORK_SOURCE/$2-$1 ]; then
        echo "== pull $2 fork $1 == has exist return"
#        rm -rf $FORK_SOURCE/$2-$1
        return
    fi
   
    mkdir -p $FORK_SOURCE

    # -rf 拷贝指定目录及其所有的子目录下文件
    cp -rf $3 $FORK_SOURCE/$2-$1
}

# ---- for 语句 ------
# $1 的取值格式为 val1 val2 val3....valn 中间为空格隔开
function fork_all() {
    for ARCH in $*
    do
        # fork ffmpeg
        fork_source_code $ARCH "ffmpeg" $LOCAL_REPO/$FFMPEG_VERSION

        # fork x264
        fork_source_code $ARCH "x264" $LOCAL_REPO/$X264_VERSION

        # fork fdkaac
        fork_source_code $ARCH "fdk-aac" $LOCAL_REPO/$FDKAAC_VERSION

        # fork mp3lame
        fork_source_code $ARCH "mp3lame" $LOCAL_REPO/$MP3LAME_VERSION
    done
}

#=== sh脚本执行开始 ==== #
# $FF_TARGET_HOST 表示脚本执行时输入的第一个参数
# 如果参数为 ffmpeg-version 则表示打印出要使用的ffmpeg版本
# 可以指定要编译的cpu架构类型，比如armv7s 也可以为all或者没有参数 表示全部cpu架构都编译
# ------ case 语句 ------
# ios|android|mac|linux|windows 表示 如果$FF_TARGET_HOST的值为ios,android,mac,linux,windows中任何一个都可以;注意这里不能替换为||
# * 表示任何字符串

# 标记是否拉取过了源码及检查了环境情况
CHECK_BUILD_ENV=build_env_check

case "$FF_TARGET_HOST" in
    ffmpeg-version)
        echo $FFMPEG_VERSION
    ;;
    clean)
        echo "----- clean forksource -----"
        if [ -d android/forksource ]; then
            rm -rf android/forksource
        fi
        echo "----- clean local source -----"
    ;;
    android)
        # 检查编译环境，比如是否安装 brew yasm gas-preprocessor.pl等等;
        if [ ! -f $CHECK_BUILD_ENV ] ;then
            echo "----- begin check build env -----"
            # sh $check-build-env.sh 用. 相当于将脚本引用进来执行，如果出错，本shell也会退出。而sh 则是重新开辟一个新shell，脚本出错不影响本shell的继续执行
            . check-build-env.sh
            touch $CHECK_BUILD_ENV
            echo "----- end check build env -----"
        fi

        FORK_SOURCE=$FF_TARGET_HOST/forksource
        # 根据情况决定是否拉取最新代码
        dowload_source_code
        fork_all $FF_ALL_ARCHS_ANDROID
    ;;
    all|*)
        echo "unsuport os !"
        exit 1
    ;;
esac
#=== sh脚本执行结束 ==== #
