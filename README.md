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
https://github.com/Huzaifa201017/Ios-Chat-App/assets/96493608/30a9b4dd-c036-47dd-aec7-0329fbfee003
### Part-2
https://github.com/Huzaifa201017/Ios-Chat-App/assets/96493608/7289df40-1e4f-4df8-a0b7-5d7a030dc549

## Images
![1](https://github.com/Huzaifa201017/Ios-Chat-App/assets/96493608/b9ffdd3d-d97d-4288-8179-9547e16d4d5f)
![2](https://github.com/Huzaifa201017/Ios-Chat-App/assets/96493608/3bbbb437-2e2b-462f-a38c-355f53b592ce)
![3](https://github.com/Huzaifa201017/Ios-Chat-App/assets/96493608/e3154b98-af54-4698-ad3f-9e479c0eee37)








