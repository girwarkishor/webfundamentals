'use strict';

var gulp = require('gulp');
var del = require('del');
var spawn = require('child_process').spawn;
var runSequence = require('run-sequence');
var plugins = require('gulp-load-plugins')();

var jekyllProcess = null;

gulp.task('rm-jekyll-build-directory', function() {
  if (jekyllProcess) {
    jekyllProcess.kill('SIGKILL');
  }

  return del([GLOBAL.WF.build.jekyll], {dot: true});
});

/**
 * There is a gotcha with this command!
 *
 * Because we are using RVM to define and lock
 * versions of GEMs, we must use
 * 'bundle exec' to execute commands againsts
 * these GEMs. This ensures Travis
 * uses it's local GEMs in vendor/bundle.
 */
function spawnkJekyllBuild(buildConfig, cb) {
  // Handle OS differences in executable name
  var jekyllCommand = process.platform === 'win32' ? 'jekyll.bat' : 'jekyll';
  var params = ['exec', jekyllCommand, 'build'];
  params.push('--config');
  params.push(
    GLOBAL.WF.src.jekyllConfigs + '/common.yml,' +
    GLOBAL.WF.src.jekyllConfigs + '/appengine.yml,' +
    GLOBAL.WF.src.jekyllConfigs + '/' + buildConfig);
  params.push('--trace');
  params.push('--profile');

  var env = Object.create(process.env);
  if (GLOBAL.WF.options.lang) {
    env.WF_BUILD_LANG = GLOBAL.WF.options.lang;
  }
  if (GLOBAL.WF.options.section) {
    env.WF_BUILD_SECTION = GLOBAL.WF.options.section;
  }

  jekyllProcess = spawn('bundle', params, {
      env: env,
      stdio: 'inherit'
    });
  jekyllProcess.on('close', function(code, signal) {
    jekyllProcess = null;

    // If we ended due to a signal to die, restart the build
    if (signal === 'SIGKILL') {
      spawnkJekyllBuild(buildConfig, cb);
    } else {
      cb();
    }
  });
}

// jekyll:target [--lang <lang_code,lang_code,...|all>]
// where 'target' is config/target.yml file.
// defaults to '--lang all'.
// 'all' builds for all languages specified in config.yml/langs_available + 'en'.
// builds w/o multilang support if config.yml is missing langs_available.
gulp.task('compile-jekyll:localhost', ['rm-jekyll-build-directory'],
  function(cb) {
    spawnkJekyllBuild('localhost.yml', cb);
  });

gulp.task('compile-jekyll:staging', ['rm-jekyll-build-directory'],
  function(cb) {
    spawnkJekyllBuild('staging.yml', cb);
  });

gulp.task('compile-jekyll:devsite', ['rm-jekyll-build-directory'],
  function(cb) {
    spawnkJekyllBuild('devsite.yml', cb);
  });
