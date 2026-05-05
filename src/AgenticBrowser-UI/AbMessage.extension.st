Extension { #name : 'AbMessage' }

{ #category : '*AgenticBrowser-UI' }
AbMessage >> asPresenter [

	^ AbMessageRichTextBuilder new richTextFor: self
]
