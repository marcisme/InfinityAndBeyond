//
//  CountPlusOneViewController.swift
//  InfinityAndBeyond
//
//  Created by Marc Schwieterman on 1/28/19.
//  Copyright © 2019 Marc Schwieterman Software, LLC. All rights reserved.
//

import UIKit

fileprivate struct Model {
    let id: Int
}

fileprivate class NetworkClient {
    enum Response {
        case success([Model])
        case failure(String)
    }

    private let delay: Double
    private let failEvery: Int
    private let callbackQueue: DispatchQueue

    private var requestCount = 0

    init(delay: Double, failEvery: Int, callbackQueue: DispatchQueue) {
        self.delay = delay
        self.failEvery = failEvery
        self.callbackQueue = callbackQueue
    }

    func fetch(offset: Int, limit: Int, completion: @escaping (Response) -> Void) {
        requestCount += 1
        // dispatch to a background queue, as an actual networking implementation would
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
            let models = (offset ..< offset + limit).map { Model(id: $0) }
            self.callbackQueue.async {
                if self.requestCount % self.failEvery == 0 {
                    completion(.failure("failing request \(self.requestCount), failing every \(self.failEvery)"))
                } else {
                    completion(.success(models))
                }
            }
        }
    }
}

fileprivate class CountPlusOneCell: UITableViewCell {
    enum State {
        case loading
        case loaded(Model)
        case error
    }

    static let identifier = "CountPlusOneCell"

    override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(for state: State) {
        switch state {
        case .loading:
            textLabel?.text = "Loading..."
            detailTextLabel?.text = nil
        case let .loaded(model):
            textLabel?.text = String(model.id)
            detailTextLabel?.text = nil
        case .error:
            textLabel?.text = "Failed to load content"
            detailTextLabel?.text = "Tap to retry"
        }
    }
}

class CountPlusOneViewController: UITableViewController {
    enum State {
        case loading
        case loaded
        case error
    }

    private let networkClient = NetworkClient(delay: 1.0, failEvery: 3, callbackQueue: DispatchQueue.main)
    private let batchSize = 20

    private var models: [Model] = []
    private var state: State = .loaded

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(CountPlusOneCell.self, forCellReuseIdentifier: CountPlusOneCell.identifier)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        // +1 for the loading/error state cell
        return models.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CountPlusOneCell.identifier) as! CountPlusOneCell

        // if we have the model, simply display it
        if indexPath.row < models.count {
            let model = models[indexPath.row]
            cell.configure(for: .loaded(model))
        } else {
            // otherwise display the loading state
            cell.configure(for: .loading)
            switch state {
            case .loading:
                // Ensure we don't make more than one network request at a time.
                // This can happen if the user scrolls to the bottom of the table, then back up a bit,
                // then back down before the network request completes.
                break
            case .loaded, .error:
                // If we're in loaded state, then we want to fetch the next batch of data.
                // If we're in an error state, we'll retry the request. This saves the user
                // from having to tap to retry, and if they happened to scroll back up then
                // back down, they may not even notice that an error occurred.
                fetch()
            }
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // If we're in the error state, set the loading message and retry
        if state == .error {
            configureLastRow(for: .loading)
            fetch()
        }
    }

    // MARK: - Implementation

    private func fetch() {
        // set the loading state, so everything else behaves correctly while the request is pending
        state = .loading
        // request the next batch of data
        let nextRange = models.count ..< models.count + batchSize
        networkClient.fetch(offset: nextRange.lowerBound, limit: nextRange.count) { response in
            // update the model/UI and set the state based on the type of response
            switch response {
            case let .success(newModels):
                self.models.append(contentsOf: newModels)
                self.state = .loaded
                if self.models.count > nextRange.count {
                    let insertedIndexPaths = nextRange.map { IndexPath(row: $0, section: 0) }
                    self.tableView.insertRows(at: insertedIndexPaths, with: .none)
                } else {
                    self.tableView.reloadData()
                }
            case .failure:
                self.state = .error
                self.configureLastRow(for: .error)
            }
        }
    }

    private func configureLastRow(for state: CountPlusOneCell.State) {
        let lastIndexPath = IndexPath(row: models.count, section: 0)
        if let cell = tableView.cellForRow(at: lastIndexPath) as? CountPlusOneCell {
            cell.configure(for: state)
        }
    }
}
