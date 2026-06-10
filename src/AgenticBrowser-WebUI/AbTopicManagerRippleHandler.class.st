"
I am the room handler for AbTopicManagerRipple.
I extend RpWebSocketEventBusHandler to call teardown on the ripple instance before unregistering,
ensuring AbTopic announcer subscriptions are properly cleaned up on disconnect.
"
Class {
	#name : 'AbTopicManagerRippleHandler',
	#superclass : 'RpWebSocketEventBusHandler',
	#category : 'AgenticBrowser-WebUI',
	#package : 'AgenticBrowser-WebUI'
}

{ #category : 'registering' }
AbTopicManagerRippleHandler >> unregister: clientWebSocket [

	| ripple |
	ripple := self rippleFor: clientWebSocket.
	ripple ifNotNil: [ :r | r teardown ].
	super unregister: clientWebSocket
]
