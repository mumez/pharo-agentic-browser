Extension { #name : 'AgenticBrowser' }

{ #category : '*AgenticBrowser-UI' }
AgenticBrowser class >> open [
	<script>
	AbSettings load.
	AbTopicManager load.
	^ AbBrowserPresenter open
]
