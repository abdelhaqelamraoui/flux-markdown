import Foundation

enum SearchLaunchClient {
    static func open(_ url: URL, completion: @escaping (Bool) -> Void) {
        guard SearchLaunchPolicy.request(url.absoluteString) != nil else { completion(false); return }
        perform { $0.openDocumentSearch(url.absoluteString, reply: $1) } completion: { completion($0) }
    }

    static func openGitHubRepository(completion: @escaping (Bool) -> Void) {
        perform { $0.openGitHubRepository(reply: $1) } completion: { completion($0) }
    }

    private static func perform(_ action: (SearchLaunchServing, @escaping (Bool) -> Void) -> Void,
                                completion: @escaping (Bool) -> Void) {
        let connection = NSXPCConnection(serviceName: SearchLaunchPolicy.serviceName)
        connection.remoteObjectInterface = NSXPCInterface(with: SearchLaunchServing.self)
        let lock = NSLock()
        var completed = false
        func finish(_ success: Bool) {
            lock.lock()
            guard !completed else { lock.unlock(); return }
            completed = true
            lock.unlock()
            connection.interruptionHandler = nil
            connection.invalidationHandler = nil
            connection.invalidate()
            DispatchQueue.main.async { completion(success) }
        }
        connection.interruptionHandler = { finish(false) }
        connection.invalidationHandler = { finish(false) }
        connection.resume()
        guard let proxy = connection.remoteObjectProxyWithErrorHandler({ _ in finish(false) }) as? SearchLaunchServing else {
            finish(false); return
        }
        action(proxy, finish)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { finish(false) }
    }
}
