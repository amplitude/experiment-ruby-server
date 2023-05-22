## [1.1.1](https://github.com/amplitude/experiment-ruby-server/compare/v1.1.0...v1.1.1) (2023-05-22)


### Bug Fixes

* pass logger to fetcher rather than debug flag ([#39](https://github.com/amplitude/experiment-ruby-server/issues/39)) ([8ec9194](https://github.com/amplitude/experiment-ruby-server/commit/8ec919459cc049483588ebbe7155b29a1108c84c))

# [1.1.0](https://github.com/amplitude/experiment-ruby-server/compare/v1.0.2...v1.1.0) (2023-03-14)


### Features

* flag dependencies ([#36](https://github.com/amplitude/experiment-ruby-server/issues/36)) ([ac92f86](https://github.com/amplitude/experiment-ruby-server/commit/ac92f865e11d072c166161af945b2461d0d8cfce))

## [1.0.2](https://github.com/amplitude/experiment-ruby-server/compare/v1.0.1...v1.0.2) (2023-01-27)


### Bug Fixes

* late require native binaries so remote code does not load them ([#35](https://github.com/amplitude/experiment-ruby-server/issues/35)) ([9073e2d](https://github.com/amplitude/experiment-ruby-server/commit/9073e2da6ccc2f8cfe7ed99d65b2b74c31f73154))

## [1.0.1](https://github.com/amplitude/experiment-ruby-server/compare/v1.0.0...v1.0.1) (2022-12-12)


### Bug Fixes

* add local evaluation repo info ([#32](https://github.com/amplitude/experiment-ruby-server/issues/32)) ([7684dcf](https://github.com/amplitude/experiment-ruby-server/commit/7684dcf9a760c6f7c3d37842dbb95dde0be91652))

# 1.0.0 (2022-12-12)


### Bug Fixes

* add arch for Docker (linux) on M1 Mac ([#28](https://github.com/amplitude/experiment-ruby-server/issues/28)) ([bc229a6](https://github.com/amplitude/experiment-ruby-server/commit/bc229a6293e7a978b489a7ed04fb9b1f104b2096))
* fix empty payload error ([#11](https://github.com/amplitude/experiment-ruby-server/issues/11)) ([e3c617c](https://github.com/amplitude/experiment-ruby-server/commit/e3c617c2cfcc67cd78462e0eb9e141230b944600))
* fix loadError for loading local evaluation function ([#21](https://github.com/amplitude/experiment-ruby-server/issues/21)) ([b25a659](https://github.com/amplitude/experiment-ruby-server/commit/b25a659e6aab0d8ac6b5f9828a940bdacd74db03))
* fix local evaluation poller interval issue ([#26](https://github.com/amplitude/experiment-ruby-server/issues/26)) ([abb7899](https://github.com/amplitude/experiment-ruby-server/commit/abb78990155d3329d8cc5f9e4889cc2111eac3a0))
* include version to resolve name error ([#7](https://github.com/amplitude/experiment-ruby-server/issues/7)) ([e7a4049](https://github.com/amplitude/experiment-ruby-server/commit/e7a40493950475c97de80f1dfb562b2218869905))
* Use correct format for string interpolation ([#27](https://github.com/amplitude/experiment-ruby-server/issues/27)) ([7e94960](https://github.com/amplitude/experiment-ruby-server/commit/7e94960eed039f3345c61cc23b8727878b58236b))
* use response.code instead of response.status when logging error ([#23](https://github.com/amplitude/experiment-ruby-server/issues/23)) ([3cdcb34](https://github.com/amplitude/experiment-ruby-server/commit/3cdcb342b50550d6e876241f08951f7e1a76ff43))


### Features

* add ampltiude cookie support ([#6](https://github.com/amplitude/experiment-ruby-server/issues/6)) ([196eed0](https://github.com/amplitude/experiment-ruby-server/commit/196eed0c75b0d6cf230ac1f0a9f34e70dc9ba755))
* add docs action ([#3](https://github.com/amplitude/experiment-ruby-server/issues/3)) ([412376d](https://github.com/amplitude/experiment-ruby-server/commit/412376d41aba4f112487402c1ee88d4ac0b39ea9))
* add local evaluation header ([#24](https://github.com/amplitude/experiment-ruby-server/issues/24)) ([04995c6](https://github.com/amplitude/experiment-ruby-server/commit/04995c61b4d09a952d63b286f75bd9538a0dfd34))
* add logger and debug support ([#4](https://github.com/amplitude/experiment-ruby-server/issues/4)) ([f627089](https://github.com/amplitude/experiment-ruby-server/commit/f6270895f28887b27bffec8b2c2c9f67169d8698))
* docs and tests update ([#5](https://github.com/amplitude/experiment-ruby-server/issues/5)) ([4251c45](https://github.com/amplitude/experiment-ruby-server/commit/4251c455498e20e8be1c1f51b8afe08c6f97709a))
* force user with sdk library ([#15](https://github.com/amplitude/experiment-ruby-server/issues/15)) ([cf98e83](https://github.com/amplitude/experiment-ruby-server/commit/cf98e83c32b77025ae759457d46150753bce47fd))
* http connection reuse ([#8](https://github.com/amplitude/experiment-ruby-server/issues/8)) ([88a0444](https://github.com/amplitude/experiment-ruby-server/commit/88a0444abbec2d33f35ce7457484c327e3f42ef4))
* local evaluation ([#16](https://github.com/amplitude/experiment-ruby-server/issues/16)) ([b049781](https://github.com/amplitude/experiment-ruby-server/commit/b0497817f331a6bc8cb962b36c1068b56150fa9a))
* setup barebone basic classes ([#2](https://github.com/amplitude/experiment-ruby-server/issues/2)) ([a9e9e03](https://github.com/amplitude/experiment-ruby-server/commit/a9e9e03ba4979e5b3aba67d49d9c94cc4ee2c62b))
* setup basic repo file and workflow ([#1](https://github.com/amplitude/experiment-ruby-server/issues/1)) ([448a2b4](https://github.com/amplitude/experiment-ruby-server/commit/448a2b4dec4b5df15c18d60ec2cc1e282e0ac15d))
* update namespace ([#13](https://github.com/amplitude/experiment-ruby-server/issues/13)) ([ceb4848](https://github.com/amplitude/experiment-ruby-server/commit/ceb4848083f82877d9fcd2227bb3bdc2bfaad5e4))
