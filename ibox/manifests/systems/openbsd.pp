# a few openbsd defaults
class ibox::systems::openbsd {
  include ib_openbsd
  include ib_pf

  include user::openbsd::defaults
}
