//
//  ViewController.swift
//  iOS Example
//
//  Created by Cirno MainasuK on 2021-6-23.
//

import UIKit
import Combine
import FPSIndicator

class ViewController: UITableViewController {
    
    var dataSource: UITableViewDiffableDataSource<String, String>!
    
    let sleepToggleBarButtonItem = UIBarButtonItem()
    let tickToggleBarButtonItem = UIBarButtonItem()
    let frameDropNumberBarButtonItem = UIBarButtonItem()
    
    var disposeBag = Set<AnyCancellable>()
    
    @Published var needSleep: Bool = true
    @Published var geigerCounterEnabled = FPSIndicator.geigerCounterEnabled
    @Published var geigerEnableWhenFrameDropBeyond = FPSIndicator.geigerEnableWhenFrameDropBeyond
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "FPS Indicator"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItems = [tickToggleBarButtonItem, frameDropNumberBarButtonItem]
        tickToggleBarButtonItem.target = self
        tickToggleBarButtonItem.action = #selector(ViewController.tickToggleBarButtonItemDidPressed(_:))
        setupTickButton()
        frameDropNumberBarButtonItem.target = self
        frameDropNumberBarButtonItem.action = #selector(ViewController.frameDropNumberBarButtonItemDidPressed(_:))
        setupFrameDropButton()
        
        navigationItem.rightBarButtonItem = sleepToggleBarButtonItem
        sleepToggleBarButtonItem.target = self
        sleepToggleBarButtonItem.action = #selector(ViewController.sleepToggleBarButtonItemDidPressed(_:))
        setupSleepButton()
        
        // bind to FPSIndicator
        $geigerCounterEnabled
            .sink { FPSIndicator.geigerCounterEnabled = $0 }
            .store(in: &disposeBag)
        $geigerEnableWhenFrameDropBeyond
            .sink { FPSIndicator.geigerEnableWhenFrameDropBeyond = $0 }
            .store(in: &disposeBag)
        
        self.dataSource = UITableViewDiffableDataSource<String, String>(tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in
            guard let self = self else { return UITableViewCell() }
            
            let _cell = tableView.dequeueReusableCell(withIdentifier: "subtitle") ?? TableViewCell(style: .subtitle, reuseIdentifier: "subtitle")
            guard let cell = _cell as? TableViewCell else { return UITableViewCell() }
            
            self.$needSleep
                .receive(on: DispatchQueue.main)
                .sink { isOn in
                    if isOn {
                        let sleepTimeInterval = TimeInterval.random(in: 0..<0.05)
                        Thread.sleep(forTimeInterval: sleepTimeInterval)
                        cell.textLabel?.text = String(format: "Sleep: %.2f", sleepTimeInterval)
                    } else {
                        cell.textLabel?.text = "No sleep"
                    }
                }
                .store(in: &cell.disposeBag)
            cell.detailTextLabel?.text = "\(indexPath.description)"
            
            return cell
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        snapshot.appendSections(["main"])
        snapshot.appendItems((0..<65535).map { String($0) }, toSection: "main")
        dataSource.apply(snapshot)
    }

}

extension ViewController {
    
    private func setupSleepButton() {
        $needSleep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needSleep in
                guard let self = self else { return }
                let imageName = needSleep ? "moon.zzz.fill" : "moon.zzz"
                self.sleepToggleBarButtonItem.image = UIImage(systemName: imageName)
                self.sleepToggleBarButtonItem.tintColor = needSleep ? .systemYellow : .label
            }
            .store(in: &disposeBag)
    }
    
    private func setupTickButton() {
        $geigerCounterEnabled
            .map { isOn in
                let imageName = isOn ? "speaker.wave.3.fill" : "speaker.slash"
                return UIImage(systemName: imageName)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: tickToggleBarButtonItem)
            .store(in: &disposeBag)
        
        $geigerCounterEnabled
            .map { isOn in return isOn ? .systemYellow : .label }
            .assign(to: \.tintColor, on: tickToggleBarButtonItem)
            .store(in: &disposeBag)
    }
    
    private func setupFrameDropButton() {
        Publishers.CombineLatest(
            $geigerCounterEnabled,
            $geigerEnableWhenFrameDropBeyond
        )
        .map { isOn, frame in
            let imageName = isOn ? "\(Int(frame)).circle.fill" : "\(Int(frame)).circle"
            return UIImage(systemName: imageName)
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.image, on: frameDropNumberBarButtonItem)
        .store(in: &disposeBag)

        Publishers.CombineLatest(
            $geigerCounterEnabled,
            $geigerEnableWhenFrameDropBeyond
        )
        .map { isOn, frame in
            guard isOn else { return .label }
            if frame >= 30 { return .systemRed }
            if frame >= 20 { return .systemYellow }
            return .systemGreen
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.tintColor, on: frameDropNumberBarButtonItem)
        .store(in: &disposeBag)
    }
    
}

extension ViewController {
    
    @objc private func tickToggleBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        geigerCounterEnabled.toggle()
    }

    @objc private func sleepToggleBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        needSleep.toggle()
    }
    
    @objc private func frameDropNumberBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        var frame = geigerEnableWhenFrameDropBeyond
        frame += 10
        if frame > 50 {     // the limitation of SF symbol
            frame = 10
        }
        geigerEnableWhenFrameDropBeyond = frame
    }

}

final class TableViewCell: UITableViewCell {
    var disposeBag = Set<AnyCancellable>()
    
    override func prepareForReuse() {
        disposeBag.removeAll()
    }
}
