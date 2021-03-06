/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class CompactViewController: UIViewController {

  @IBOutlet weak var collectionView: UICollectionView!
  var dataSource = PokemonDataSource()

  var favorites: [Pokemon] = []

  let numberOfItemPerRow = 3
  let interItemSpacing = 8
  let horizontalPadding: CGFloat = 12
  let verticalPadding: CGFloat = 8

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.register(UINib(nibName: "EmptyFavoritesCell", bundle: nil), forCellWithReuseIdentifier: EmptyFavoritesCell.reuseIdentifier)
    collectionView.register(UINib(nibName: "CompactPokemonCell", bundle: nil), forCellWithReuseIdentifier: CompactPokemonCell.reuseIdentifier)
    collectionView.dataSource = dataSource
    collectionView.delegate = self
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    collectionView.collectionViewLayout.invalidateLayout()
  }

}

extension CompactViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    CGSize(width: UIScreen.main.bounds.width, height: 50)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let fullWidth = UIScreen.main.bounds.width - horizontalPadding * 2
    let totalSpacing = numberOfItemPerRow * interItemSpacing

    if dataSource.isFavoritesSection(indexPath.section) && dataSource.favorites.isEmpty {
      return CGSize(width: fullWidth, height: fullWidth / 3)
    }

    let itemWidth = (Int(fullWidth) - totalSpacing) / numberOfItemPerRow
    return CGSize(width: itemWidth, height: itemWidth)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return CGFloat(interItemSpacing)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
  }

}

extension CompactViewController {
  // I shouldve used CompositionalLayout to make the My Pokemons part scroll horizontally.
  // Will do that after i do the second part.
  func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {

    // if this is a "No pokemons" cell, do nothing
    if indexPath.section == 0 && dataSource.favorites.isEmpty {
      return nil
    }

    let selectedPokemon = indexPath.section == 0
      ? self.dataSource.favorites[indexPath.item]
      : self.dataSource.pokemons[indexPath.item]

    let identifier = "\(indexPath)" as NSString

    return UIContextMenuConfiguration(identifier: identifier,
                                      previewProvider: nil) { _ in
      self.makeCompactCellMenu(for: selectedPokemon)
    }
  }

  func makeCompactCellMenu(for pokemon: Pokemon, with title: String = "") -> UIMenu {
    var menuItems: [UIAction] = []

    if let favPokemonIndex = dataSource.favorites.firstIndex(where: { (favPokemon) -> Bool in
      favPokemon.pokemonID == pokemon.pokemonID
    }) {

      let removeMenu = UIAction(title: "Remove from favorites",
                                image: UIImage(systemName: "heart.slash")) { _ in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
          /* the above line is a workaround for the bug that apple gave us with simultaneous contextmenu and collectionviewitem deletion animations */
          self.deletePokemon(at: favPokemonIndex)
        }
      }

      menuItems.append(removeMenu)
    } else {
      let addMenu = UIAction(title: "That's my favorite!",
                             image: UIImage(systemName: "heart.fill")) { _ in
        self.addPokemon(pokemon)
      }
      menuItems.append(addMenu)
    }

    return UIMenu(title: title, children: menuItems)
  }

  func deletePokemon(at dataSourceIndex: Int) {
    collectionView.performBatchUpdates({
      self.dataSource.removeFromFavorites(at: dataSourceIndex)


      if self.dataSource.favorites.isEmpty {
        self.collectionView.reloadSections(IndexSet(integer: 0))
      } else {
        let indexPath = IndexPath(item: dataSourceIndex, section: 0)
        self.collectionView.deleteItems(at: [indexPath])
      }
    })
  }

  func addPokemon(_ pokemon: Pokemon) {
    let isFavoritesEmpty = self.dataSource.favorites.isEmpty
    self.dataSource.addToFavorites(pokemon: pokemon)
    if isFavoritesEmpty {
      self.collectionView.reloadSections(IndexSet(integer: 0))
    } else {
      let indexPath = IndexPath(item: self.dataSource.favorites.count - 1, section: 0)
      self.collectionView.insertItems(at: [indexPath])
    }
  }
}

