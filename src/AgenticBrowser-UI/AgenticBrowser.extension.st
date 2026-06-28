Extension { #name : 'AgenticBrowser' }

{ #category : '*AgenticBrowser-UI' }
AgenticBrowser class >> open [
	<script>
	(AbBrowserPresenter allInstances anySatisfy: [ :e |
		 e window notNil and: [ e window isOpen ] ]) ifFalse: [
		AbSettings load.
		AbTopicManager load ].
	^ AbBrowserPresenter open
]
