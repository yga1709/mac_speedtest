#!/bin/bash

# 入力判定
yorn(){
	ret=-1
	echo $1 [y/N]
	read key
	time while true;do
		case $key in
			y)
				ret=0
				return 0
				;;
			Y)
				ret=0
				return 0
				;;
			n)
				ret=1
				return 1
				;;
			N)
				ret=1
				return 1
				;;
			*)
				echo "不正な値"
				;;
			esac
		done
}

main(){
	printf "Mac用 スピードテストツール version 0.1 作成者:Aiyama Ryo \n \n 当ツールでは以下のテストを行います。\n [1] h265エンコードテスト \n [2] 連番画像生成テスト \n [3] 画像アップスケーリングテスト \n \n テストを行うには、以下のツールがインストールされている必要があります。 \n - Videotoolboxに対応したffmpeg \n - waifu2x-cocoa \n \n"
	
	yorn "実行を開始しますか？"
	if [ $ret -eq 1 ]; then
		exit 0
	fi
	
	init
	
	echo "ツールで使用するh264コーデックの動画ファイルを入力してください。（3分以下推奨）"
	read movie
	if [ -e $movie -a -r $movie ]; then
		movie_path=$movie
	fi
	
	test_flg=5
	
	yorn "[1] h265への変換テストを実行しますか？"
	if [ $ret -eq 0 ]; then
		convert_h265 $movie_path
		test_flg=$[$test_flg+1]
	fi
	
	yorn "[2] 連番画像の変換テストを実行しますか？（[3] 画像のアップスケーリングテストを行う場合には必須です。"
	if [ $ret -eq 0 -a $test_flg -ge 1 ]; then
		convert_images $movie_path
		test_flg=$[$test_flg+1]
	fi
	
	yorn "[3] 画像のアップスケーリングテストを実行しますか？"
	if [ $ret -eq 0 -a $test_flg -ge 2 ]; then
		upscale_images
		test_flg=$[$test_flg+1]
	fi
	
	echo 【テスト結果】
	cat ./macspeedtest/$result_file | column -s , -t
	terminate
	echo テストを終了します。
	unset TIMEFORMAT
}

init(){
	unset TIMEFORMAT
	TIMEFORMAT='%R,%U,%S,%P'
	
	mkdir -p ./macspeedtest
	mkdir -p ./macspeedtest/1
	mkdir -p ./macspeedtest/2
	mkdir -p ./macspeedtest/3
	
	result_file=result_$(date +%Y%m%d%H%M%S).csv
	touch ./macspeedtest/$result_file
	echo 経過時間,ユーザCPU時間,システムCPU時間,CPU使用率 >> ./macspeedtest/$result_file
}

convert_h265(){
	echo "Videotoolboxによるh265変換を開始します。"
	bitrate=$(ffprobe -v quiet -i $1 -show_entries format=bit_rate | sed -n 2P | cut -d "=" -f 2)
	(time ffmpeg -i $1 -c:v hevc_videotoolbox -c:a copy -b:v $bitrate -loglevel error ./macspeedtest/1/h265.mkv) >> ./macspeedtest/$result_file 2>&1
}

convert_images(){
	echo "ffmpegによる連番画像の変換を開始します。"
	(time ffmpeg -i $1 -loglevel error -vcodec png -r 10 ./macspeedtest/2/image%04d.png) >> ./macspeedtest/$result_file 2>&1
}

upscale_images_wrapper(){
	echo "waifu2xによる画像のアップスケーリング処理を開始します。"
	cd ./macspeedtest/2/
	(time upscale_images_core) 2>&1
	cd ../../
}

upscale_images_core(){
	for file in *; do
    	waifu2x -s 2 -n 0 -i ${file} -o ../3/${file} > /dev/null 2>&1
	done
}

terminate(){
	yorn "変換したファイルを削除しますか？（ファイルが残ったまま次のテストを行うと、正しく動作しません。Noを選択された場合は、次のテストを行う前に必ず自分でファイルの削除をしてください。）"
	if [ $ret -eq 0]; then
		rm -rd ./macspeedtest
	fi
}

main