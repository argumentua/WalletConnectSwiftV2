
import Foundation

class Sequences<T: Sequence> {
    let serialQueue = DispatchQueue(label: "sequence queue: \(UUID().uuidString)")
    private var sequences: [T] = []
    
    func create(topic: String, sequenceState: SequenceState) {
        let sequence = T(topic: topic, sequenceState: sequenceState)
        serialQueue.sync {
            sequences.append(sequence)
        }
    }
    
    func getAll() -> [T] {
        serialQueue.sync {
            sequences
        }
    }
    
    func getSettled() -> [SequenceSettled] {
        getAll().compactMap { sequence in
            switch sequence.sequenceState {
            case .settled(let settled):
                return settled
            case .pending(_):
                return nil
            }
        }
    }
    
    func get(topic: String) -> T? {
        serialQueue.sync {
            sequences.first{$0.topic == topic}
        }
    }

    func update(topic: String, newTopic: String? = nil, sequenceState: SequenceState) {
        guard let sequence = get(topic: topic) else {return}
        serialQueue.sync {
            if let newTopic = newTopic {
                sequence.topic = newTopic
            }
            sequence.sequenceState = sequenceState
        }
    }
    
    func delete(topic: String) {
        Logger.debug("Will delete sequence for topic: \(topic)")
        serialQueue.sync {
            sequences.removeAll {$0.topic == topic}
        }
    }
}