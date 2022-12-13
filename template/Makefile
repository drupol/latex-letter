letter ?= letter1

build-letter :
	pandoc src/$(letter)/*.md -s --template=template-letter.tex -o $(letter).pdf
