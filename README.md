# Ios-Chat-App
My first full-stack IOS app, using Firebase.  
Category: Chat App.  
Level: Beginner/Intermediate. 

## Features
+ Login/Sign Up using firebase(email/password login)
+ Real-Time Chat
+ Video Messages
+ Image Messages
+ Text Messages
+ Delete Conversations
+ Sign Out
+ Search Users to start a new Conversation

## Design Patterns Used
+ Singleton

## Supported Ios Versions
 13.0 - 16.0

## Issues
+ When a sender starts a new conversation by sending a message, to make this message displayed you have to move to the back page i.e. conversations page, and then come back again. This issue is related to the file ChatViewController, and it's because of the asynchronous nature of the function called 'createNewConversation', actually what happens there is that, the function to load messages gets called first and the function to load messages to the database called later, because of this we get zero messages at that time.
+ Second issue is that because of internet lag, sometimes the image message is sent but sometimes it's not, idk why, so these are two main issues right now.
## Instructions
To run this project, you must first execute the command `pod install` in the project's directory and then open the .xcworkspace file and run it.

## Video
### Part-1

https://github.com/Huzaifa201017/Ios-Chat-App/assets/96493608/f6746848-6aad-4793-a190-04239fa3e911


### Part-2


https://github.com/Huzaifa201017/Ios-Chat-App/assets/96493608/67dbdcb2-c504-4247-855f-06a68b3c418b











