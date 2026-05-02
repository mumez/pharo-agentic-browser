Extension { #name : 'AbMessage' }

{ #category : '*AgenticBrowser-UI' }
AbMessage >> asPresenter [

	| p |
	p := AbMessagePresenter new.
	p updateMessage: self.
	^ p
]
