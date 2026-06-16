Extension { #name : 'AgenticBrowser' }

{ #category : '*AgenticBrowser-WebUI' }
AgenticBrowser class >> startWebUI [
	<script>
	AbSettings load.
	AbTopicManager load.
	^ AbTopicManagerRipple startWebUIServer
]
