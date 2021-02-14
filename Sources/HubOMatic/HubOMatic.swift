
import Foundation
import MiscKit


public struct HubOMatic {
    struct Config : Hashable, Codable {
        var repository: URL
    }

    var text = "Hello, World!"

    public init() {

    }
}

public extension HubOMatic {
    func start() { 
    }
}



//import Foundation
//import OSLog
//
///// Local handle for logging events.
//private let events: OSLog = .init(subsystem: "net.hubomatic.Events", category: "XPC")
//
//
///// XPC interface for returning folder contents.
//@objc protocol FinderInterface {
//
//    /// Loads files from the given folder
//    /// - Parameter path: Path in Finder.
//    /// - Parameter reply: Callback with a list of files.
//    func filesInFolder(_ path: String, reply: @escaping ([String], Error?) -> Void)
//
//    func shellCommand(_ command: String, reply: @escaping (String?, Error?) -> Void)
//
//}
//
//
//// TODO:
//// /usr/bin/curl https://github.com/parquette/parquette/releases/latest/download/Parquette.zip > Parquette.zip
//// /usr/bin/ditto -x -k Parquette.zip .
//// /usr/bin/xattr -d -r 'com.apple.quarantine' Parquette.app
//// /bin/mv Parquette.app /Applications/
//// Process.runTask(command: "/bin/sh", arguments: ["-c", "(while /bin/kill -0 \(pid) >&/dev/null; do /bin/sleep 0.2; done; /usr/bin/xattr -d -r 'com.apple.quarantine' '\(appPath)'; /usr/bin/open '\(appPath)') &"])
//
//extension Process {
//    public static func shell(script: String, privileged: Bool = false) throws -> String? {
//        let task = Process()
//        let pipe = Pipe()
//
//        task.launchPath = "/bin/sh"
//        task.arguments = ["-c", script]
//        task.standardOutput = pipe
//        try task.run()
//
//        let handle = pipe.fileHandleForReading
//        let data = handle.readDataToEndOfFile()
//        let output = String(data: data, encoding: String.Encoding.utf8)
//        return output
//    }
//}
//
///// Live connection to the given XPC service.
//final public class XPC<P> {
//
//    /// Bundle identifier of a XPC service.
//    public let serviceName: String
//
//    /// Callback for unexpected XPC errors.
//    public let errorHandler: (_ error: Error) -> Void
//
//    /// Current XPC state.
//    @Atomic
//    private var cachedState: (connection: NSXPCConnection, proxy: P)? {
//        willSet {
//            cachedState?.connection.invalidate()
//        }
//    }
//
//    /// Creates a live XPC connection.
//    /// - Parameter serviceName: Bundle identifier of a XPC service.
//    /// - Parameter errorHandler: Callback for unexpected XPC errors.
//    /// - Parameter error: XPC error.
//    public init(serviceName: String, errorHandler: @escaping (_ error: Error) -> Void) {
//        self.serviceName = serviceName
//        self.errorHandler = errorHandler
//    }
//
//    /// Cleanup XPC connection.
//    deinit {
//        self.cachedState = nil
//    }
//}
//
//// MARK: - Internal API
//
//public extension XPC {
//
//    /// Performs a XPC operation.
//    /// - Parameter handler: Callback with a proxy object.
//    /// - Parameter proxy: Remote object interface.
//    func callProxy(_ handler: (_ proxy: P) -> Void) {
//        do {
//            handler(try proxy())
//        } catch {
//            cachedState = nil
//            errorHandler(error)
//        }
//    }
//}
//
//// MARK: - Private API
//
//private extension XPC {
//
//    /// Used to create a XPC if needed and returns a proxy or an error.
//    func proxy() throws -> P {
//        if let state = cachedState {
//            return state.proxy
//        }
//
//        // Service protocol cannot be created from `String(describing: P.self)` so we use a method `dump` and strip special characters
//        var dumpOutput = ""
//        _ = dump(P.self, to: &dumpOutput)
//        let components = dumpOutput.components(separatedBy: " ")
//        guard let protocolName = components.first(where: { $0.contains(".") }), let serviceProtocol = NSProtocolFromString(protocolName) else {
//            os_log(.error, log: events, "Invalid Proxy Type")
//            throw CocoaError(.xpcConnectionInvalid)
//        }
//
//        let connection = NSXPCConnection(serviceName: serviceName)
//        connection.remoteObjectInterface = .init(with: serviceProtocol)
//        connection.resume()
//        connection.interruptionHandler = { [weak self] in
//            os_log(.error, log: events, "Exit or Crash")
//            self?.errorHandler(CocoaError(.xpcConnectionInterrupted))
//        }
//        let anyProxy = connection.remoteObjectProxyWithErrorHandler { [weak self] error in
//            os_log(.error, log: events, "No Reply: %{public}s", String(describing: error))
//            self?.errorHandler(error)
//        }
//        guard let proxy = anyProxy as? P else {
//            os_log(.error, log: events, "Invalid Proxy Type")
//            throw CocoaError(.xpcConnectionInvalid)
//        }
//        cachedState = (connection, proxy)
//        return proxy
//    }
//}
//
//
///// Lightweight atomic accessor.
//@propertyWrapper
//public class Atomic<Value> {
//
//  /// Underlying value.
//  private var value: Value
//
//  /// Lightweight lock.
//  private var lock: os_unfair_lock_s = .init()
//
//  /// Property wrapper requirement.
//  public var wrappedValue: Value {
//    get { access { $0 } }
//    set { access { $0 = newValue } }
//  }
//
//  /// Creates a new accessor with the given initial value.
//  /// - Parameter value: Initial value.
//  public init(wrappedValue value: Value) {
//    self.value = value
//  }
//}
//
//// MARK: - Private API
//
//private extension Atomic {
//
//  /// Provides mutable access to the underlying value.
//  func access<T>(_ accessor: (inout Value) -> T) -> T {
//    os_unfair_lock_lock(&lock)
//    defer { os_unfair_lock_unlock(&lock) }
//    return accessor(&value)
//  }
//}
