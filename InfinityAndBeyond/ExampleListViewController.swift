//
//  ExampleListViewController.swift
//  InfinityAndBeyond
//
//  Created by Marc Schwieterman on 1/29/19.
//  Copyright © 2019 Marc Schwieterman Software, LLC. All rights reserved.
//

import UIKit

class ExampleListViewController: UITableViewController {
    enum Example: Int, CaseIterable {
        case countPlusOne

        var name: String {
            switch self {
            case .countPlusOne:
                return "Count + 1"
            }
        }

        func newViewController() -> UIViewController {
            let vc: UIViewController
            switch self {
            case .countPlusOne:
                vc = CountPlusOneViewController()
            }
            vc.navigationItem.title = name
            return vc
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return Example.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell")!
        let example = Example(rawValue: indexPath.row)!
        cell.textLabel?.text = example.name
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let example = Example(rawValue: indexPath.row)!
        navigationController?.pushViewController(example.newViewController(), animated: true)
    }
}
