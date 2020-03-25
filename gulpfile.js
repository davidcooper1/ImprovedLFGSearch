const gulp = require("gulp");
const exec = require("child_process").exec;
const watch = require("gulp-watch");
//const log = require("fancy-log");

const log = console.log.bind(console);

function deploy() {
    exec("PowerShell -ExecutionPolicy Bypass -File .\\localdeploy.ps1 -ProjectName=" + process.env.ProjectName, function(err, stdout, stderr) {
        log(stdout);
    });
}
gulp.task("deploy", function(cb) {
    deploy();
});

gulp.task("deploy-watch", function() {
    return watch(process.env.ProjectName + "/*.*", {verbose: true}, function() {
        deploy();
    });
});
