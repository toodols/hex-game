#![recursion_limit = "999"]

use std::{
    env,
    fs::{self},
};

use full_moon::{
    ast::{
        self,
        punctuated::{Pair, Punctuated},
        span::ContainedSpan,
        Call, Expression, Field, FunctionArgs, FunctionCall, Suffix,
    },
    print,
    tokenizer::{Symbol, Token, TokenReference, TokenType},
    visitors::VisitorMut,
};

use if_chain::if_chain;
use regex::Regex;

fn token_ref(token: Token) -> TokenReference {
    return TokenReference::new(vec![], token, vec![]);
}

struct FirstPass;
impl VisitorMut for FirstPass {
    fn visit_function_call(&mut self, node: FunctionCall) -> FunctionCall {
        let prefix = node.prefix();
        let mut suffixes: Vec<Suffix> = node.suffixes().map(|s| s.clone()).collect();
        if_chain! {
            if let ast::Prefix::Name(prefix_token) = prefix;
            if prefix_token.token().to_string() == "React";
            if let ast::Suffix::Index(ast::Index::Dot { name, .. }) = &suffixes[0];
            if name.token().to_string() == "createElement";
            if let Suffix::Call(call) = &mut suffixes[1];
            if let Call::AnonymousCall(FunctionArgs::Parentheses { ref mut arguments, .. }) = call;
            let mut iter = arguments.iter_mut();
            if let Some(component) = iter.next();
            if let Some(props) = iter.next();
            let children = iter.next();
            then {

                // use Corner component in place of UICorner intrinsic
                if component.to_string() == "\"UICorner\"" {
                    let mut arguments = Punctuated::new();
                    arguments.push(Pair::new(Expression::Var(ast::Var::Name(TokenReference::new(
                        vec![],
                        Token::new(
                            TokenType::Identifier { identifier: "Corner".into() }
                        ),
                        vec![]
                    ))), None));
                    let suffixes = vec![suffixes[0].clone(), Suffix::Call(
                        Call::AnonymousCall(FunctionArgs::Parentheses { parentheses: ContainedSpan::new(
                            token_ref(Token::new(TokenType::Symbol { symbol: Symbol::LeftParen })),
                            token_ref(Token::new(TokenType::Symbol { symbol: Symbol::RightParen })),
                        ), arguments }
                    ))];
                    return node.with_suffixes(suffixes);
                }


                // remove redundant props
                if let Expression::TableConstructor(props_table_constructor) = props {

                    let mut new_fields: Punctuated<Field> = Punctuated::new();
                    let mut background_transparency_is_1 = false;

                    for field in props_table_constructor.fields() {
                        if_chain! {
                            if let Field::NameKey { key, equal, value } = field;
                            if key.token().to_string() == "BackgroundTransparency";
                            if let Expression::Number(number) = value;
                            if number.token().to_string() == "1";
                            then {
                                background_transparency_is_1 = true;
                            }
                        }
                    }
                    for field in props_table_constructor.fields() {
                        if let Field::NameKey { key, equal, value } = field {
                            let key_string = key.token().to_string();
                            if key_string == "Transparency" {
                                if let Expression::Number(number) = value {
                                    if number.token().to_string() == "1" {
                                        continue
                                    }
                                }
                            } else if background_transparency_is_1 {
                                if matches!(key_string.as_str(), "BackgroundColor3" | "BorderColor3" | "BorderSizePixel") {
                                    continue
                                }
                            }

                        }
                        let new_field = field.clone();
                           new_fields.push(Pair::new(
                           new_field,
                           Some(token_ref(Token::new(TokenType::Symbol { symbol: Symbol::Comma})))
                           ))
                    }
                    *props_table_constructor = props_table_constructor.clone().with_fields(new_fields);
                }

                // rename child props so they don't have numbers in their names
                if let Some(Expression::TableConstructor(children_table_constructor)) = children {
                    let mut new_fields: Punctuated<Field> = Punctuated::new();
                    for field in children_table_constructor.fields() {
                        let mut new_field = field.clone();
                        if let Field::NameKey { key, equal, value } = field {
                            let key_string = key.token().to_string();
                            let pat = Regex::new("([a-zA-Z]+)\\d*").unwrap();
                            let new_name = pat.captures(&key_string).map(|c| c[1].to_string()).unwrap_or(key_string.clone());
                            println!("{} -> {}", key_string, new_name);
                            if pat.is_match(&key_string) {
                                match new_field {
                                    Field::NameKey { ref mut key, .. } => {
                                        *key = token_ref(Token::new(TokenType::Identifier { identifier: new_name.into() }))
                                    }
                                    _ => {}
                                }
                            }
                        }
                        new_fields.push(Pair::new(
                           new_field,
                           Some(token_ref(Token::new(TokenType::Symbol { symbol: Symbol::Comma})))
                           ))
                    }
                    *children_table_constructor = children_table_constructor.clone().with_fields(new_fields);
                }
                return node.with_suffixes(suffixes)
            }
        }
        return node;
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let code = fs::read_to_string(&args[1]).expect("Could not read file");
    let ast = full_moon::parse(&code).expect("Failed to parse");

    let ast = FirstPass.visit_ast(ast);

    let out = print(&ast);
    println!("{:?}", args);
    fs::write(&args.get(2).unwrap_or(&args[1]), out).expect("Failed to write file");
}
