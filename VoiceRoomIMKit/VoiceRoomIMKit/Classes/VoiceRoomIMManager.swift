//
//  VoiceRoomIMManager.swift
//  Pods-VoiceRoomIMKit_Tests
//
//  Created by 朱继超 on 2022/9/1.
//

import Foundation
import AgoraChat

public let VoiceRoomGift = "chatroom_gift"
public let VoiceRoomPraise = "chatroom_praise"//like 点赞
public let VoiceRoomInviteSite = "chatroom_inviteSiteNotify"
public let VoiceRoomApplySite = "chatroom_applySiteNotify"

@objc public protocol VoiceRoomIMDelegate: NSObjectProtocol {
    
    func receiveTextMessage(roomId: String,message: AgoraChatMessage)
    
    func receiveGift(roomId: String, meta: [String:String]?)
        
    func receiveApplySite(roomId: String, meta: [String:String]?)
    
    func receiveInviteSite(roomId: String, meta: [String:String]?)
    
    func userJoinedRoom(roomId: String, username: String)
    
    func announcementChanged(roomId: String, content: String)
    
    func userBeKicked(roomId: String, reason: AgoraChatroomBeKickedReason)
    
    func roomAttributesDidUpdated(roomId: String, attributeMap: [String : String]?, from fromId: String)
    
    func roomAttributesDidRemoved(roomId: String, attributes: [String]?, from fromId: String)
}

@objcMembers public class VoiceRoomIMManager:NSObject,AgoraChatManagerDelegate,AgoraChatroomManagerDelegate {
    
    public var currentRoomId = ""
    
    static var shared: VoiceRoomIMManager? = VoiceRoomIMManager()
    
    public weak var delegate: VoiceRoomIMDelegate?
    
    func configIM(appkey: String) {
        let options = AgoraChatOptions(appkey: appkey.isEmpty ? "easemob-demo#easeim":appkey)
        options.enableConsoleLog = true
        options.isAutoLogin = true
        options.setValue(false, forKeyPath: "enableDnsConfig")
        options.setValue(6717, forKeyPath: "chatPort")
        options.setValue("52.80.99.104:6717", forKeyPath: "chatServer")
        options.setValue("http://a1-test.easemob.com", forKeyPath: "restServer")
        AgoraChatClient.shared().initializeSDK(with: options)
    }
    
    func addChatRoomListener() {
        AgoraChatClient.shared().chatManager?.add(self, delegateQueue: .main)
        AgoraChatClient.shared().roomManager?.add(self, delegateQueue: .main)
    }
    
    deinit {
        AgoraChatClient.shared().roomManager?.remove(self)
        AgoraChatClient.shared().chatManager?.remove(self)
    }
}

public extension VoiceRoomIMManager {
    
    //MARK: - AgoraChatManagerDelegate
    func messagesDidReceive(_ aMessages: [AgoraChatMessage]) {
        for message in aMessages {
            if message.to != self.currentRoomId {
                continue
            }
            if message.body is AgoraChatTextMessageBody {
                if self.delegate != nil,self.delegate!.responds(to: #selector(VoiceRoomIMDelegate.receiveTextMessage(roomId:message:))) {
                    self.delegate?.receiveTextMessage(roomId: self.currentRoomId, message: message)
                }
                continue
            }
            if let body = message.body as? AgoraChatCustomMessageBody {
                if self.delegate != nil {
                    switch body.event {
                    case VoiceRoomGift:
                        if self.delegate!.responds(to: #selector(VoiceRoomIMDelegate.receiveGift(roomId:meta:))) {
                            self.delegate?.receiveGift(roomId: self.currentRoomId, meta: body.customExt)
                        }
                    case VoiceRoomInviteSite:
                        if self.delegate!.responds(to: #selector(VoiceRoomIMDelegate.receiveInviteSite(roomId:meta:))) {
                            self.delegate?.receiveInviteSite(roomId: self.currentRoomId, meta: body.customExt)
                        }
                    case VoiceRoomApplySite:
                        if self.delegate!.responds(to: #selector(VoiceRoomIMDelegate.receiveApplySite(roomId:meta:))) {
                            self.delegate?.receiveApplySite(roomId: self.currentRoomId, meta: body.customExt)
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
    //MARK: - AgoraChatroomManagerDelegate
    func didReceiveUserJoinedChatroom(_ aChatroom: AgoraChatroom, username aUsername: String) {
        if self.delegate != nil,self.delegate!.responds(to: #selector(VoiceRoomIMDelegate.userJoinedRoom(roomId:username:))) {
            if let roomId = aChatroom.chatroomId,roomId == self.currentRoomId  {
                self.delegate?.userJoinedRoom(roomId: roomId, username: aUsername)
            }
        }
    }
    
    func chatroomAnnouncementDidUpdate(_ aChatroom: AgoraChatroom, announcement aAnnouncement: String?) {
        if self.delegate != nil,self.delegate!.responds(to: #selector(VoiceRoomIMDelegate.announcementChanged(roomId:content:))) {
            if let roomId = aChatroom.chatroomId,let announcement = aAnnouncement,roomId == self.currentRoomId  {
                self.delegate?.announcementChanged(roomId: roomId, content: announcement)
            }
        }
    }
    
    func didDismiss(from aChatroom: AgoraChatroom, reason aReason: AgoraChatroomBeKickedReason) {
        if self.delegate != nil,self.delegate!.responds(to: #selector(VoiceRoomIMDelegate.userBeKicked(roomId:reason:))) {
            if let roomId = aChatroom.chatroomId,roomId == self.currentRoomId  {
                self.delegate?.userBeKicked(roomId: roomId, reason: aReason)
            }
        }
        switch aReason {
        case .beRemoved,.destroyed:
            AgoraChatClient.shared().roomManager?.remove(self)
            AgoraChatClient.shared().chatManager?.remove(self)
            self.currentRoomId = ""
        default:
            break
        }
    }
    
    func chatroomAttributesDidUpdated(_ roomId: String, attributeMap: [String : String]?, from fromId: String) {
        if self.delegate != nil,self.delegate!.responds(to: #selector(VoiceRoomIMDelegate.roomAttributesDidUpdated(roomId:attributeMap:from:))),roomId == self.currentRoomId  {
            self.delegate?.roomAttributesDidUpdated(roomId: roomId, attributeMap: attributeMap, from: fromId)
        }
    }
    
    func chatroomAttributesDidRemoved(_ roomId: String, attributes: [String]?, from fromId: String) {
        if self.delegate != nil,self.delegate!.responds(to: #selector(VoiceRoomIMDelegate.roomAttributesDidRemoved(roomId:attributes:from:))),roomId == self.currentRoomId {
            self.delegate?.roomAttributesDidRemoved(roomId: roomId, attributes: attributes, from: fromId)
        }
    }
    
    //MARK: - Send
    func sendMessage(_ roomId: String, _ text: String,_ completion: @escaping (AgoraChatMessage?,AgoraChatError?) -> (Void)) {
        let message = AgoraChatMessage(conversationID: roomId, body: AgoraChatTextMessageBody(text: text), ext: nil)
        AgoraChatClient.shared().chatManager?.send(message, progress: nil, completion: completion)
    }
    
    func joinedChatRoom(_ roomId: String,_ completion: @escaping ((AgoraChatroom?,AgoraChatError?)->())) {
        AgoraChatClient.shared().roomManager?.joinChatroom(roomId, completion: { room, error in
            if error == nil,let id = room?.chatroomId {
                self.currentRoomId = id
            }
            completion(room,error)
        })
    }
    
    func userQuitRoom(_ completion: @escaping ((AgoraChatError?)->())) {
        AgoraChatClient.shared().roomManager?.leaveChatroom(self.currentRoomId, completion: { error in
            if error == nil {
                AgoraChatClient.shared().roomManager?.remove(self)
                AgoraChatClient.shared().chatManager?.remove(self)
                self.currentRoomId = ""
            }
            completion(error)
        })
    }
}
