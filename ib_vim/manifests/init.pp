# deploy a sane vimrc
class ib_vim {
  require ::vim

  file{'/etc/vimrc':
    source => 'puppet:///modules/ib_vim/vimrc',
  }
}
