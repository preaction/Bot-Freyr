requires "DBM::Deep" => "0";
requires "Import::Base" => "0.006";
requires "Mojo::IRC" => "0";
requires "Mojolicious" => "0";
requires "Moo::Lax" => "0";
requires "Type::Tiny" => "0";
requires "curry" => "0";
requires "experimental" => "0";
requires "perl" => "5.020";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "Test::Compile" => "0";
  requires "Test::Deep" => "0";
  requires "Test::Differences" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};
