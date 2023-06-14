-- ref. https://ginkouno.hatenablog.jp/entry/2019/07/21/194117
-- ref. https://qiita.com/terrierscript/items/22ad9efcac90127f87a1
-- 導入しようとしたが、使うたびにrsyncで間に合いそうなのでまた今度
settings {
  logfile = "/tmp/lsyncd.log",
  statusFile = "/tmp/lsyncd.status",
  insist = true,
  nodaemon = true,
  statusInterval = 10,
  maxProcesses = 1,
}

sync {
  default.rsyncssh,
  delete = false,
  delay = 0,
  source = "/Users/ginkouno/project/awesome",
  host = "192.168.0.111",
  targetdir = "project",
  rsync = {
    binary = "/usr/local/bin/rsync",
    archive = true,
    compress = true,
    rsh = "/usr/bin/ssh -i /Users/ginkouno/.ssh/id_rsa -l ginkouno"
  }
}
