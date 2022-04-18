# iosp2ptest
iOSP2PTest uses Multipeer Connectivity to achieve data sharing between two iOS devices.

Author: Zhiyuan Huang

## How to Run:
### Step 1: Clone Git Repository
Clone the git repository with `git clone https://github.com/Revelation999/iosp2ptest.git`

### Step 2: Open simulation
Double click the file p2ptest.xcodeproj with Xcode to open the project. Once Xcode finishes loading, click "run" on the top left to open a simulation. 
A simulator of iOS system with the project application should launch short after.

### Step 3: Test Multipeer Connectivity
Inside the simulated application, either click the top-left "share" button to host or join a session, or click the top-right "add" button to create a message.
#### Hosting/Joining a session:
- Clicking the host option will allow your device to be detected by other devices in the local network using the same application.
- When trying to join a session, the application will display a list of devices hosting within your local network.
#### Create a message:
- Clicking the "add" button opens a prompts that allows you to enter a message. After clicking "done", the message will be displayed on the table view of the application.
  Adding a message on your device will also create a message on every device that is in the same session as yours, whether they are hosting or joining.
  
## Custom Data Structures
```swift
struct TextItem : Codable {
    
    var source:String
    var message:String
    var date:Date
    var uuid:UUID
    
}
```

A `TextItem` represents one message added by a device. It consists of the device's name in `UIDevice`, the message string, a time stamp and a unique identifier. 
A `TextItem` is codable so that it can be encoded into and decoded from JSON format.

## Data Manager Functions (inside DataManager.swift)
- `static func save <T:Encodable> (_ object:T, with fileName:String)` converts a codable object into JSON format and save it in a local file with the specified file name.
- `static func load <T:Decodable> (_ fileName:String, with type:T.Type) -> T` decode the specified file from JSON format and returns the object.
- `static func loadData (_ fileName:String) -> Data?` retrieves the raw data from the specified file and returns it (without decoding).
- `static func loadAll <T:Decodable> (_ type:T.Type) -> [T]` calls the `load()` function on all files within a directory.
- `static func delete (_ fileName:String)` deletes the file of the specified name
