//
//  ViewController.swift
//  iOS Example
//
//  Created by Cirno MainasuK on 2021-6-23.
//

import UIKit
import Combine

class ViewController: UITableViewController {

    var dataSource: UITableViewDiffableDataSource<String, String>!

    let sleepToggleBarButtonItem = UIBarButtonItem()

    var disposeBag = Set<AnyCancellable>()
    let needSleep = CurrentValueSubject<Bool, Never>(true)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        title = "FPS Indicator"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = sleepToggleBarButtonItem
        sleepToggleBarButtonItem.target = self
        sleepToggleBarButtonItem.action = #selector(ViewController.sleepToggleBarButtonItemDisPressed(_:))
        
        needSleep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needSleep in
                guard let self = self else { return }
                let imageName = needSleep ? "moon.zzz.fill" : "moon.zzz"
                self.sleepToggleBarButtonItem.image = UIImage(systemName: imageName)
                self.sleepToggleBarButtonItem.tintColor = needSleep ? .systemYellow : .label
            }
            .store(in: &disposeBag)

        self.dataSource = UITableViewDiffableDataSource<String, String>(tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in
            guard let self = self else { return UITableViewCell() }

            let cell = tableView.dequeueReusableCell(withIdentifier: "subtitle") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "subtitle")
            if self.needSleep.value {
                let sleepTimeInterval = TimeInterval.random(in: 0..<0.05)
                Thread.sleep(forTimeInterval: sleepTimeInterval)
                cell.textLabel?.text = String(format: "Sleep: %.2f", sleepTimeInterval)
            } else {
                cell.textLabel?.text = "No sleep"
            }
            cell.detailTextLabel?.text = "\(indexPath.description)"
            return cell
        }

        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        snapshot.appendSections(["main"])
        snapshot.appendItems((0..<65535).map { String($0) }, toSection: "main")
        dataSource.apply(snapshot)
    }

    @objc private func sleepToggleBarButtonItemDisPressed(_ sender: UIBarButtonItem) {
        needSleep.value.toggle()
        tableView.reloadData()
    }

}

