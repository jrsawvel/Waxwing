package App::Dispatch;
use strict;
use warnings;
use App::Modules;

my %cgi_params = Utils::get_cgi_params_from_path_info("function", "one", "two", "three", "four");

my $dispatch_for = {
    showerror      =>   sub { return \&do_sub(       "Utils",          "do_invalid_function"      ) },
    add            =>   sub { return \&do_sub(       "Image",          "display_add_image_form"   ) },
    upload         =>   sub { return \&do_sub(       "Image",          "display_upload_image_form") },
    addimage       =>   sub { return \&do_sub(       "Image",          "add_image"                ) },
    test           =>   sub { return \&do_sub(       "Image",          "do_test"                  ) },
    addimagejson   =>   sub { return \&do_sub(       "Image",          "add_image_json"           ) },
    stream         =>   sub { return \&do_sub(       "Stream",         "show_stream"              ) },
    post           =>   sub { return \&do_sub(       "Post",           "show_post"                ) },
    searchform     =>   sub { return \&do_sub(       "Stream",         "show_search_form"         ) },
    tag            =>   sub { return \&do_sub(       "Stream",         "tag_search"               ) },
    search         =>   sub { return \&do_sub(       "Stream",         "search"                   ) },
    login          =>   sub { return \&do_sub(       "User",           "show_login_form"          ) },
    dologin        =>   sub { return \&do_sub(       "User",           "mail_login_link"          ) },
 nopwdlogin        =>   sub { return \&do_sub(       "User",           "no_password_login"        ) },
    delete         =>   sub { return \&do_sub(       "Post",           "delete"                   ) },
    deleted        =>   sub { return \&do_sub(       "Stream",         "show_deleted_posts"       ) },
    undelete       =>   sub { return \&do_sub(       "Post",           "undelete"                 ) },
};

sub execute {
    my $function = $cgi_params{function};

    $dispatch_for->{stream}->() if !defined($function) or !$function;

#    $dispatch_for->{showerror}->($function) unless exists $dispatch_for->{$function} ;
    $dispatch_for->{post}->($function) unless exists $dispatch_for->{$function} ;

    defined $dispatch_for->{$function}->();
}

sub do_sub {
    my $module = shift;
    my $subroutine = shift;
    eval "require App::$module" or Page->report_error("user", "Runtime Error (1):", $@);
    my %hash = %cgi_params;
    my $coderef = "$module\:\:$subroutine(\\%hash)"  or Page->report_error("user", "Runtime Error (2):", $@);
    eval "{ &$coderef };" or Page->report_error("user", "Runtime Error (2):", $@) ;
}

1;
