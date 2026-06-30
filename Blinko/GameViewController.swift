import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func loadView() {
        self.view = SKView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let view = self.view as? SKView else { return }

        let scene = MenuScene(size: UIScreen.main.bounds.size)
        scene.scaleMode  = .resizeFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        view.presentScene(scene)
        view.ignoresSiblingOrder = true

        #if DEBUG
        view.showsFPS       = true
        view.showsNodeCount = true
        #endif
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var prefersStatusBarHidden: Bool { true }
}
