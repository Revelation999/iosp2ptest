//
//  MessageTableViewController.swift
//  p2ptest
//
//  Created by Zhiyuan Huang on 2/25/22.
//

import UIKit
import MultipeerConnectivity

class MessageTableViewController: UITableViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    //Variables for both AC and Small AC
    var state:Float32 = Float32(Int8.random(in: 0..<1))
    var round:Int = 0
    var started:Bool = false
    var smallAC:Bool = true
    
    //Variables for AC
    var localStates:[String:[TextItem]]!
    var currentStates:[String:Float32]!
    var logItems:[LogItem]!
    
    //Variables for SMall AC
    var deviceOrder:Int!
    var minState:Float32!
    var maxState:Float32!
    var peerIDs:Array<String>!
    var hasReceivedFromNode:Array<Bool>!
    
    var peerID:MCPeerID!
    var mcSession:MCSession!
    var mcAdvertiserAssistant:MCAdvertiserAssistant!
    
    @IBAction func initiateProtocol(_ sender: Any) {
        if (self.mcSession.connectedPeers.count > 0) {
            started = true
            if (!self.smallAC) {
                ACAlg(TextItem(source: self.peerID.displayName, message: self.state, round: self.round))
            } else {
                smallACAlg()
                
            }
        }
        /*let addAlert = UIAlertController(title: "New Message", message: "Enter the message", preferredStyle: .alert)
        addAlert.addTextField { (textfield:UITextField) in
            textfield.placeholder = "Text"
        }
        
        addAlert.addAction(UIAlertAction(title: "Create", style: .default, handler: { (action:UIAlertAction) in
            
            guard let text = addAlert.textFields?.first?.text else { return }
            let newMessage = TextItem(source: UIDevice.current.name, message: self.state, round: self.round)
            //newMessage.saveItem()
            
            self.textItems.append(newMessage)
            
            let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)
            
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            
            self.shareTextMessage(newMessage)
            
        }))
        
        addAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(addAlert, animated: true, completion: nil)*/
    }
    
    @IBAction func showConnectivityAction(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Message Exchange", message: "Do you want to Host or Join a session?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Host Session", style: .default, handler: { (action:UIAlertAction) in
            
            self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "p2ptest", discoveryInfo: nil, session: self.mcSession)
            self.mcAdvertiserAssistant.start()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Join Session", style: .default, handler: { (action:UIAlertAction) in
            let mcBrowser = MCBrowserViewController(serviceType: "p2ptest", session: self.mcSession)
            mcBrowser.delegate = self
            self.present(mcBrowser, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    /*func shareTextMessage(_ textItem:TextItem) {
        if mcSession.connectedPeers.count > 0 {
            if let textData = DataManager.loadData(textItem.uuid.uuidString) {
                do {
                    try mcSession.send(textData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    fatalError("Cannot send text data")
                }
            }
        }
    }*/
    
    func setUpConnectivity() {
        peerID = MCPeerID(displayName: UIDevice.current.identifierForVendor!.uuidString)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpConnectivity()
        loadData()
    }
    
    func loadData() {
        logItems = [LogItem]()
        logItems = DataManager.loadAll(LogItem.self).sorted(by: {
            $0.date < $1.date
        })
        tableView.reloadData()
    }
    
    func ACAlg(_ initialState: TextItem) {
        broadcast(initialState)
        var count:Int = 0
        while (true) {
            if (currentStates.values.count > self.mcSession.connectedPeers.count / 2) {
                count = 0
                self.state = currentStates.values.reduce(0, +) / Float32(currentStates.values.count)
                let roundLog = LogItem(round: self.round, currentState: self.currentStates, date: Date(), uuid: UUID())
                DataManager.save(roundLog, with: roundLog.uuid.uuidString)
                self.loadData()
                currentStates.removeAll()
                self.round += 1
                for (source, messages) in localStates {
                    for message in messages {
                        if (message.round == self.round) {
                            currentStates[source] = message.message
                        }
                    }
                }
                let newText = TextItem(source: UIDevice.current.identifierForVendor!.uuidString, message: self.state, round: self.round)
                broadcast(newText)
                
                if (self.round == 100) {
                    print("Broadcast complete for this node.")
                    localStates.removeAll()
                    self.started = false
                    break
                }
            } else {
                count += 1
            }
            if (count >= 1_000_000_000) {
                fatalError("Cannot complete process")
            }
        }
    }
    
    func smallACAlg () {
        DispatchQueue.global().async {
            self.unreliableBroadcast()
        }
        self.peerIDs = self.mcSession.connectedPeers.map{$0.displayName}
        self.peerIDs.append(self.peerID.displayName)
        self.peerIDs.sort{$0 < $1}
        self.deviceOrder = self.peerIDs.firstIndex(of: self.peerID.displayName)
        self.minState = self.state
        self.maxState = self.state
        self.hasReceivedFromNode = Array(repeating: false, count: self.mcSession.connectedPeers.count)
        while (true) {
            if (self.round >= 100) {
                self.started = false
                break
            }
        }
        print(String(format: "Final state", self.state))
    }
    
    func reset() {
        self.hasReceivedFromNode = self.hasReceivedFromNode.map{$0 && false}
        self.hasReceivedFromNode[self.deviceOrder] = true
        self.minState = self.state
        self.maxState = self.state
    }
    
    func store(_ message : Float32){
        if (self.minState > message) {
            self.minState = message
        }
        if (self.maxState < message) {
            self.maxState = message
        }
    }
    
    func unreliableBroadcast() {
        let encoder = JSONEncoder()
        while (true) {
            do {
                try mcSession.send(encoder.encode(TextItem(source: self.peerID.displayName, message: self.state, round: self.round)), toPeers: mcSession.connectedPeers, with: .unreliable)
            } catch {
                fatalError("Cannot send message")
            }
            if (!started) {
                break
            }
        }
    }
    
    func broadcast(_ message : TextItem) {
        let encoder = JSONEncoder()
        do {
            try mcSession.send(encoder.encode(message), toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Cannot send message")
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MessageTableViewCell

        // Configure the cell...
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        let logItem = logItems[indexPath.row]
        cell.sourceLabel.text = String(logItem.round)
        let jsonData = try? JSONSerialization.data(withJSONObject: logItem.currentState, options: [])
        cell.messageLabel.text = String(data: jsonData!, encoding: .utf8)
        cell.timeLabel.text = dateFormatter.string(from: logItem.date)
        return cell
    }
    
    //MC functions

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        @unknown default:
            fatalError()
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if (!self.started) {
            self.started = true
            if (!self.smallAC) {
                DispatchQueue.main.async {
                    self.ACAlg(TextItem(source: self.peerID.displayName, message: self.state, round: self.round))
                }
            } else {
                DispatchQueue.main.async {
                    self.smallACAlg()
                }
                
            }
        }
        if (!self.smallAC) {
            do {
                let textItem = try JSONDecoder().decode(TextItem.self, from: data)
                localStates[textItem.source, default: []].append(textItem)
                if (textItem.round == self.round) {
                currentStates[textItem.source] = textItem.message
                }
            } catch {
                fatalError("Unable ot process the received data.")
            }
        } else {
            do {
                let textItem = try JSONDecoder().decode(TextItem.self, from: data)
                if (textItem.round > self.round) {
                    self.round = textItem.round
                    self.state = textItem.message
                    self.reset()
                } else if (textItem.round == self.round && !self.hasReceivedFromNode[self.peerIDs.firstIndex(of: textItem.source) ?? -1]) {
                    self.hasReceivedFromNode[self.peerIDs.firstIndex(of: textItem.source) ?? -1] = true
                    self.store(textItem.message)
                    if (self.hasReceivedFromNode.filter{$0}.count > self.mcSession.connectedPeers.count / 2) {
                        self.state = (self.minState + self.maxState) / 2
                        self.round += 1
                        self.reset()
                    }
                }
                
            } catch {
                fatalError("Unable to process the received data")
            }
        }

    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
}
