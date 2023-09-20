import axios from "axios";
import FormData from "form-data";
import "dotenv/config";

const { PINATA_JWT } = process.env;

const JWT = `Bearer ${PINATA_JWT}`

const MAIN_URL = "https://xkcd.com/";

const urls = [
    "512",
    "303",
    "356",
    "435",
    "927",
    "199",
    "849",
    "1289",
    "835",
    "1343",
    "217",
    "221",
    "2385",
    "327",
]

async function uploadToPinata(sourceUrl: string) {

    const axiosInstance = axios.create();
  
    const data = new FormData();
  
    const response = await axiosInstance(sourceUrl, {
      method: "GET",
      responseType: "stream",
    });
    data.append(`file`, response.data);
  
    try {
      const res = await axios.post("https://api.pinata.cloud/pinning/pinFileToIPFS", data, {
        //maxBodyLength: "Infinity",
        headers: {
            'Content-Type': `multipart/form-data; boundary=${data.getBoundary()}`,
            'Authorization': JWT
        }
      });

      return res.data;
    } catch (error) {
      console.log(`error on ${sourceUrl}`, error)
    }
    return null;
};


async function pinJsonToPinata(jsonString: string){
    var config = {
        method: 'post',
        url: 'https://api.pinata.cloud/pinning/pinJSONToIPFS',
        headers: { 
          'Content-Type': 'application/json', 
          'Authorization': JWT
        },
        data : jsonString
    };

    try {
        const res = await axios(config);
        // console.log(res.data);
        return res.data;
    } catch (error) {
        console.log("ERROR", error)
    }
    return null;
} 

async function downloadImage(url: string){
    const response = await fetch(MAIN_URL + url + "/info.0.json");
    const resp = await response.json();
    const imageUrl = resp["img"];
    const imgHash = (await uploadToPinata(imageUrl))["IpfsHash"];

    var data = JSON.stringify({
        "pinataOptions": {
          "cidVersion": 1
        },
        "pinataMetadata": {
          "name": `XKCD_${url}.json`,
          "keyvalues": {
            "XKCD id": url,
          }
        },
        "pinataContent": {
          "name": `My awesome XKCD NFT: ${url}`,
          "description": `This is a NFT of XKCD comic number ${url}, which is titled: ${resp["title"]}; ${resp["alt"]}`,
          "image": `ipfs://${imgHash}`,
        }
      });

      const jsonResponse = await pinJsonToPinata(data);

      return {
        "metadataHash": jsonResponse["IpfsHash"], 
        "imgHash": imgHash, 
        "imageId": url
    };

}


function prepareSolidityFile(data: {metadataHash: string;imgHash: string;imageId: string;}[]): string{
  return (
      "\t" + `string[${data.length}] uidLinks = [\n${data.map((d) => `\t\t"ipfs://ipfs/${d.metadataHash}"`).join(",\n")}\n\t];\n`
  )
}

async function main(){
    const res = await Promise.all(urls.map(url => downloadImage(url)));
    console.log(prepareSolidityFile(res));
}

main().then(() => process.exit(0))

/*
const responseData = [
    {
      metadataHash: 'bafkreieybi64qgt2nd24ht7e5bkgcfmallurlyqrtufftbzlh65sei4zrq',
      imgHash: 'QmTUjuWu3erxrzPt6qvMotfPGorYCH1ckMD2frGKJpJeb4',
      imageId: '512'
    },
    {
      metadataHash: 'bafkreigxf6kwo7qq2nds4b4vzqhyy7yj37hkdfkwhs24xy6rayvbf5yfgy',
      imgHash: 'QmQXk6EDEeoY75gEGAkd2AGebYRtHPM5VX3tEVSqYxXGki',
      imageId: '303'
    },
    {
      metadataHash: 'bafkreichupmk6f4uxwvy4izkswlyu3viwlyqaabjwreyd6j3f66tyw33ge',
      imgHash: 'QmRuQN9XS7sHZeF74uoJ6zzezoXiGVfskAwjexx4mUSgGs',
      imageId: '356'
    },
    {
      metadataHash: 'bafkreidruphdcmqb2s5ibympfmuilpuzd64xj3xlu7sruffy2w7hw3oo4u',
      imgHash: 'QmQRtfKRuZ9RVLJEeKzQnmnLrfRbyGYN5JHM6v64rmhWCL',
      imageId: '435'
    },
    {
      metadataHash: 'bafkreiadsbrd4knarjarfmcswxye762h5gcfigdk4xqq4wud2rwhnxttsm',
      imgHash: 'QmaHkEgzRdocAK3bvZWjhxvoHv2kAKkmMwyoQcxbUGVKxg',
      imageId: '927'
    },
    {
      metadataHash: 'bafkreiat7y3wez6e6autxn73mvjluoxc5gjwzrcjmlrv3outxnm4wdar7m',
      imgHash: 'QmQaJ5hiREUEFDYyf3LmbPvgjL6CyRv3X2HzpE9F9yNKUH',
      imageId: '199'
    },
    {
      metadataHash: 'bafkreieg6xotxyxetew65fg47iy4peu2vsjjr67raxlz5nkm65ebvolrx4',
      imgHash: 'QmXfmzqJWbtXv3ytACY2QFHGuiNcP3mqa1T28qnLmBVyPb',
      imageId: '849'
    },
    {
      metadataHash: 'bafkreia3j4oparmlz37kzq5msoix55nz25ucsfgsv5euhuss72vrcmin34',
      imgHash: 'Qmeq6AEUsr2Pzz1i5xV6uVe8pELxdaGydcuFCpgY868KTB',
      imageId: '1289'
    },
    {
      metadataHash: 'bafkreiawnajxljlztnxyu23hodvysac37seio7scvfwjyb6gqrdomc5gxe',
      imgHash: 'QmV3bHSMRbNYydNxpyuke659Nj89UsVcuSyZXibogw4sJ9',
      imageId: '835'
    },
    {
      metadataHash: 'bafkreigvq7766epo3bhpg67oxfuxlofzjt2a6ht2aj2suwdviwezs4l4mq',
      imgHash: 'QmUetDXUjE5a9QssfCDorCc6sdzDw5skRvCp3e9U8r8X4H',
      imageId: '1343'
    },
    {
      metadataHash: 'bafkreigniof2fm2ooeiwomvhachcu2kj74rgz43j4665fcff6tkovmqvs4',
      imgHash: 'Qme8e9aX26uVKeXcvTfuqUJ1UbSWq6toYqHmzX7Z8Pjjn4',
      imageId: '217'
    },
    {
      metadataHash: 'bafkreiaqdet3dm2rwpgj4xgi7l2ypefqukanwkeqykajojinuhhbqptpqi',
      imgHash: 'QmVWTzdzoK2znNPexzdFoZ7HGiTUCQG7Hh3xqy94czyJQC',
      imageId: '221'
    },
    {
      metadataHash: 'bafkreidejgskxyv6orhpitmq6oxg4meizm6iqeypvx7yymtdbuel7s3itq',
      imgHash: 'QmPhQxNVgFEVbMCEtgTFU1bCV4AFUnJxQ5SVvHo1GNipsS',
      imageId: '2385'
    },
    {
      metadataHash: 'bafkreieitl5zfhrwvtnu42gcd5mozuqjcbrrv7vwr2ur7nnxcztmemm4yq',
      imgHash: 'Qmc2scYoF9FmCdbRk6P4X5nqSosiUbuAvXwmyaKWiFo4iD',
      imageId: '327'
    }
]
*/
