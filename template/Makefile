letter ?= letter1

build-letter :
	pandoc src/$(letter)/*.md --from markdown --to latex -s --template=template-letter.tex -o $(letter).pdf
