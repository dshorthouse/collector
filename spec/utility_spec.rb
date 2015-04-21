# encoding: utf-8
require_relative "./spec_helper"

describe "Utility functions to handle names of people" do
  before(:all) do
    @utility = Collector::Utility
  end

  it "should remove 'et al'" do
    input = "Jack Smith et al"
    expected = ["Jack Smith"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should remove 'et al.'" do
    input = "Jack Smith et al."
    expected = ["Jack Smith"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should remove 'and others'" do
    input = "Jack Smith and others"
    expected = ["Jack Smith"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should remove '& others'" do
    input = "Jack Smith and others"
    expected = ["Jack Smith"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should remove 'etc'" do
    input = "Jack Smith etc"
    expected = ["Jack Smith"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should remove 'etc.'" do
    input = "Jack Smith etc."
    expected = ["Jack Smith"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should remove ', YYYY' " do
    input = "Jack Smith, 2009"
    expected = ["Jack Smith"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should remove brackets from name" do
    input = "W.P. Coreneuk(?)"
    expected = ["W. P. Coreneuk"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode by 'stet!'" do
    input = "Jack Smith stet! 1989"
    expected = ["Jack Smith"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode by 'stet'" do
    input = "Jack Smith stet 1989"
    expected = ["Jack Smith"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode by 'stet,'" do
    input = "Jack Smith stet, 1989"
    expected = ["Jack Smith"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should remove 'UNKNOWN'" do
    input = "UNKNOWN"
    expected = []
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should remove extraneous material" do
    input = "Unknown [J. S. Erskine?]"
    expected = ["J. S. Erskine"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should remove more exteneous material" do
    input = "Jack [John]: Smith12345"
    expected = ["Jack John Smith"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with '-'" do
    input = "Jack Smith - Yves St-Archambault"
    expected = ["Jack Smith", "Yves St-Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with '–'" do
    input = "Jack Smith   –   Yves St-Archambault"
    expected = ["Jack Smith", "Yves St-Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'and'" do
    input = "Jack Smith and Yves Archambault"
    expected = ["Jack Smith", "Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'AND'" do
    input = "Jack Smith AND Yves Archambault"
    expected = ["Jack Smith", "Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with ';'" do
    input = "Jack Smith; Yves Archambault"
    expected = ["Jack Smith", "Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with '|'" do
    input = "Jack Smith | Yves Archambault"
    expected = ["Jack Smith", "Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with '&'" do
    input = "Jack Smith & Yves Archambault"
    expected = ["Jack Smith", "Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with '/'" do
    input = "Jack Smith / Yves Archambault"
    expected = ["Jack Smith", "Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'et'" do
    input = "Jack Smith et Yves Archambault"
    expected = ["Jack Smith", "Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'with'" do
    input = "Jack Smith with Yves Archambault"
    expected = ["Jack Smith", "Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'annotated'" do
    input = "annotated Yves Archambault"
    expected = ["Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'annotated by'" do
    input = "annotated by Yves Archambault"
    expected = ["Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'conf'" do
    input = "Jack Johnson conf Yves Archambault"
    expected = ["Jack Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'conf'" do
    input = "Jack Johnson conf Yves Archambault"
    expected = ["Jack Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'conf.'" do
    input = "Jack Johnson conf. Yves Archambault"
    expected = ["Jack Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'conf by'" do
    input = "Jack Johnson conf by Yves Archambault"
    expected = ["Jack Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'conf. by'" do
    input = "Jack Johnson conf. by Yves Archambault"
    expected = ["Jack Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'confirmed by'" do
    input = "Jack Johnson confirmed by Yves Archambault"
    expected = ["Jack Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'checked by'" do
    input = "Jack Johnson checked by Yves Archambault"
    expected = ["Jack Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'Checked By'" do
    input = "Checked By Yves Archambault"
    expected = ["Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'dupl'" do
    input = "Jack Johnson dupl Yves Archambault"
    expected = ["Jack Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'dupl.'" do
    input = "Jack Johnson dupl. Yves Archambault"
    expected = ["Jack Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'dup by'" do
    input = "Jack Johnson dup by Yves Archambault"
    expected = ["Jack Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'dup. by'" do
    input = "Jack Johnson dup. by Yves Archambault"
    expected = ["Jack Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'ex. by'" do
    input = "Rex Johnson ex. by Yves Archambault"
    expected = ["Rex Johnson","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'ex by'" do
    input = "Rex Byron ex by Yves Archambault"
    expected = ["Rex Byron","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'examined by'" do
    input = "Rex Byron examined by Yves Archambault"
    expected = ["Rex Byron","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'in part'" do
    input = "Rex Byron in part Yves Archambault"
    expected = ["Rex Byron","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'in part by'" do
    input = "Rex Byron in part by Yves Archambault"
    expected = ["Rex Byron","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'redet by'" do
    input = "Jack Smith redet. by Michael Jackson"
    expected = ["Jack Smith", "Michael Jackson"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'stet'" do
    input = "Anna Roberts stet R. Scagel 1981"
    expected = ["Anna Roberts", "R. Scagel"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'ver by'" do
    input = "Rex Byron ver by Yves Archambault"
    expected = ["Rex Byron","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'ver. by'" do
    input = "Rex Byron ver. by Yves Archambault"
    expected = ["Rex Byron","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode names with 'verified by'" do
    input = "Rex Byron verified by Yves Archambault"
    expected = ["Rex Byron","Yves Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode concatenated names like 'Yves R.Archambault'" do
    input = "Rex Byron and Yves R.Archambault"
    expected = ["Rex Byron","Yves R. Archambault"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode concatenated names like 'J.L.Gentry Jr.'" do
    input = "J.L.Gentry Jr."
    expected = ["J. L. Gentry Jr."]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode concantenated names and deal with 'Ver By'" do
    input = "S.Ross Ver By P. Perrin"
    expected = ["S. Ross", "P. Perrin"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should explode a complicated example" do
    input = "Vernon C. Brink; Thomas C. Brayshaw stet! 1979"
    expected = ["Vernon C. Brink", "Thomas C. Brayshaw"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should reject an empty name" do
    input = "Norman Johnson and P"
    expected = ["Norman Johnson"]
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should reject a long name" do
    input = "Ontario Ministry of Natural Resources"
    expected = []
    expect(@utility.explode_names(input)).to match_array(expected)
  end

  it "should parse name with given initials without period(s)" do
    input = "JH Picard"
    parsed = Namae.parse @utility.explode_names(input)[0]
    cleaned = @utility.clean_namae(parsed).to_h
    expected = { family: "Picard", given: "J.H."}
    expect(cleaned).to eq(expected)
  end

  it "should capitalize surnames like 'Jack smith'" do
    input = "Jack smith"
    parsed = Namae.parse @utility.explode_names(input)[0]
    cleaned = @utility.clean_namae(parsed).to_h
    expected = { family: "Smith", given: "Jack"}
    expect(cleaned).to eq(expected)
  end

  it "should capitalize names like 'C. YOUNG'" do
    input = "C. YOUNG"
    parsed = Namae.parse @utility.explode_names(input)[0]
    cleaned = @utility.clean_namae(parsed).to_h
    expected = { family: "Young", given: "C."}
    expect(cleaned).to eq(expected)
  end

  it "should properly handle and capitalize utf-8 characters" do
    input = "Sicard, Léas"
    parsed = Namae.parse @utility.explode_names(input)[0]
    cleaned = @utility.clean_namae(parsed).to_h
    expected = { family: "Sicard", given: "Léas"}
    expect(cleaned).to eq(expected)
  end

end
