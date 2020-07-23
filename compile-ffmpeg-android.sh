#! /usr/bin/env bash

set -e

# 由于目前设备基本都是电脑64位 手机64位 所以这里脚本默认只支持 arm64 x86_64两个平台
# FF_ALL_ARCHS_ANDROID="armv5 armv7a arm64 i386 x86_64"
export FF_ALL_ARCHS_ANDROID="armv7a arm64 x86_64"
# 编译的API级别 (最小5.0以上系统)
export FF_ANDROID_API=21
# 根据实际情况填写ndk路径;(备注:mac和linux平台下，如果从小于19和19以上版本之间切换过ndk版本，那么最好先删掉android/forksource目录重新编译拉取代码，
# 否则编译fdk-aac时会出现libtool执行错误,导致编译结束)
# export NDK_PATH=/Users/markmjw/App/android-sdk-macosx/android-ndk-r16b
export NDK_PATH=/Users/markmjw/App/android-sdk-macosx/ndk-bundle

# 开启编译动态库，默认开启
export FF_COMPILE_SHARED=TRUE
# 开启编译静态库,默认关闭,动态库和静态库同时只能开启一个，不然导入android使用时会出错
export FF_COMPILE_STATIC=FALSE

# 是否将这些外部库添加进去;如果不添加 则将对应的值改为FALSE即可；默认添加2个库
export lIBS=(x264 fdk-aac mp3lame)
export LIBFLAGS=(TRUE TRUE FALSE)

#----------
UNI_BUILD_ROOT=`pwd`
FF_TARGET=$1

# 配置外部库
config_external_lib()
{
    for(( i=0;i<${#lIBS[@]};i++)) 
    do
        #${#array[@]}获取数组长度用于循环
        lib=${lIBS[i]};
        FF_ARCH=$1
        FF_BUILD_NAME=$lib-$FF_ARCH
        FFMPEG_DEP_LIB=$UNI_BUILD_ROOT/android/build/$FF_BUILD_NAME/lib
        if [[ ${LIBFLAGS[i]} == "TRUE" ]]; then
            if [ ! -f "${FFMPEG_DEP_LIB}/lib$lib.a" ] && [ $FF_COMPILE_STATIC = "TRUE" ]; then
                # 编译
                . ./android/do-compile-$lib.sh $FF_ARCH
            fi
            if [ ! -f "${FFMPEG_DEP_LIB}/lib$lib.so" ] && [ $FF_COMPILE_SHARED = "TRUE" ]; then
                # 编译
                . ./android/do-compile-$lib.sh $FF_ARCH
            fi
        fi
    done;
}


# 命令开始执行处----------
if [ "$FF_TARGET" = "armv7a" -o "$FF_TARGET" = "arm64" -o "$FF_TARGET" = "x86_64" ]; then
    
    # 开始之前先检查fork的源代码是否存在
    . ./compile-init.sh android "offline"
    
    # 清除之前编译的
    rm -rf android/build/ffmpeg*
	
    # 先编译外部库
    config_external_lib $FF_TARGET
    
    # 最后编译ffmpeg;第二个参数代表开启了编译GDB调试器用的调试信息;备注：不管静态库还是动态库，都无法调试。
    . ./android/do-compile-ffmpeg.sh $FF_TARGET
#    . ./android/do-compile-ffmpeg.sh $FF_TARGET debug
    
elif [ "$FF_TARGET" = "all" ]; then
    # 开始之前先检查fork的源代码是否存在
    . ./compile-init.sh android "offline"
    
    # 清除之前编译的
    rm -rf android/build/ffmpeg-*
	
    for ARCH in $FF_ALL_ARCHS_ANDROID
    do
        # 先编译外部库
        config_external_lib $ARCH
        
        # 最后编译ffmpeg
        . ./android/do-compile-ffmpeg.sh $ARCH
    done

elif [ "$FF_TARGET" == "pull" ]; then
    # 重新拉取所有代码
    echo "....repull all source...."
    . ./compile-init.sh android
elif [ "$FF_TARGET" = "clean" ]; then

    echo "----- begin clean -----"
#    for ARCH in $FF_ALL_ARCHS_ANDROID
#    do
#        echo "clean ffmpeg-$ARCH"
#        echo "=================="
#        cd android/forksource/ffmpeg-$ARCH && git clean -xdf && cd -
#        cd android/forksource/x264-$ARCH && git clean -xdf && cd -
#        cd android/forksource/mp3lame-$ARCH && make clean && cd -
#        cd android/forksource/fdk-aac-$ARCH && make clean && cd -
#    done
    rm -rf android/forksource
    rm -rf android/build
    echo "----- end clean -----"
    
else
    echo "Usage:"
    echo "  compile-ffmpeg.sh armv7a|arm64|x86_64"
    echo "  compile-ffmpeg.sh all"
    echo "  compile-ffmpeg.sh clean"
    echo "  compile-ffmpeg.sh pull"
    exit 1
fi
