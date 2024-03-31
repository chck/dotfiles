function ip() {
  echo $(ipconfig getifaddr en0)
}

function clean_downloads() {
  # :param duration: Filter downloads based on the file modification time in fd command such as "7 days".
  duration=$1
  fd -0 --changed-before "${duration}" --hidden . ~/Downloads | xargs -0 -I {} mv {} ~/.Trash
}

function png2svg() {
  # :param png_image: PNG Image file path which you want to convert SVG
  png_image=$1
  convert -flatten "${png_image}" /tmp/output.ppm
  potrace -s /tmp/output.ppm -o ${png_image%.png}.svg
  rm /tmp/output.ppm
}
