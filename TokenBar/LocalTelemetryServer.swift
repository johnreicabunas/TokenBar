import Foundation
import Network

final class LocalTelemetryServer {
    static let port: NWEndpoint.Port = 47831
    private let onEvent: (TelemetryEvent) -> Void
    private let queue = DispatchQueue(label: "TokenBar.LocalTelemetryServer")
    private var listener: NWListener?

    init(onEvent: @escaping (TelemetryEvent) -> Void) {
        self.onEvent = onEvent
    }

    func start() {
        guard listener == nil else { return }
        do {
            let parameters = NWParameters.tcp
            parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: Self.port)
            let listener = try NWListener(using: parameters)
            listener.newConnectionHandler = { [weak self] in self?.handle($0) }
            listener.start(queue: queue)
            self.listener = listener
        } catch {
            listener = nil
        }
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, _, _ in
            guard let self, let data else {
                connection.cancel()
                return
            }
            let body = data.split(separator: Data("\r\n\r\n".utf8), maxSplits: 1).last.map { Data($0) } ?? Data()
            if body.count <= 32_768, let event = try? TelemetryEvent.decode(body) {
                self.onEvent(event)
                self.respond(connection, status: "200 OK")
            } else {
                self.respond(connection, status: "400 Bad Request")
            }
        }
    }

    private func respond(_ connection: NWConnection, status: String) {
        let response = Data("HTTP/1.1 \(status)\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".utf8)
        connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
    }
}
